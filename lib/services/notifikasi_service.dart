// lib/services/notifikasi_service.dart
//
// Service notifikasi yang sync dengan backend API Laravel.
// Notifikasi dibuat server-side saat admin menyetujui/menolak surat,
// lalu Flutter mengambil data via GET /api/notifikasi.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import './auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './offline_database_service.dart';
import './alert_service.dart';

// ============================================================
//  MODEL NOTIFIKASI (dari server)
// ============================================================

enum TipeNotifikasi {
  pengajuanBaru,
  pengaduanBaru,
  pengaduanTerkirim,
  respons,
  disetujui,
  ditolak,
}

class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final TipeNotifikasi tipe;
  final DateTime waktu;
  bool sudahDibaca;
  final String? relatedId;
  final String ikon;

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.waktu,
    this.sudahDibaca = false,
    this.relatedId,
    required this.ikon,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    TipeNotifikasi tipe;
    switch (json['tipe']?.toString()) {
      case 'disetujui':
        tipe = TipeNotifikasi.disetujui;
        break;
      case 'ditolak':
        tipe = TipeNotifikasi.ditolak;
        break;
      case 'pengajuan_baru':
        tipe = TipeNotifikasi.pengajuanBaru;
        break;
      case 'pengaduan_baru':
        tipe = TipeNotifikasi.pengaduanBaru;
        break;
      case 'pengaduan_terkirim':
        tipe = TipeNotifikasi.pengaduanTerkirim;
        break;
      default:
        tipe = TipeNotifikasi.respons;
    }

    return NotifikasiItem(
      id: json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      pesan: json['pesan']?.toString() ?? '',
      tipe: tipe,
      waktu: json['waktu'] != null
          ? DateTime.tryParse(json['waktu'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sudahDibaca: json['sudahDibaca'] == true,
      relatedId: json['relatedId']?.toString(),
      ikon: json['ikon']?.toString() ?? '🔔',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'pesan': pesan,
        'tipe': tipe.name,
        'waktu': waktu.toIso8601String(),
        'sudahDibaca': sudahDibaca,
        'relatedId': relatedId,
        'ikon': ikon,
      };
}

// ============================================================
//  SERVICE
// ============================================================

class NotifikasiService extends ChangeNotifier {
  static final NotifikasiService _instance = NotifikasiService._internal();
  factory NotifikasiService() => _instance;
  NotifikasiService._internal();

  final List<NotifikasiItem> _list = [];
  final Set<String> _deletedIds = {};
  // Set ID notifikasi yang sudah pernah ditampilkan (untuk deteksi notif baru)
  final Set<String> _knownIds = {};
  bool _isLoaded = false;
  bool _isFetching = false;
  Timer? _periodicTimer;

  List<NotifikasiItem> get notifikasi => List.unmodifiable(_list);
  List<NotifikasiItem> get belumDibaca =>
      _list.where((n) => !n.sudahDibaca).toList();
  int get jumlahBelumDibaca => belumDibaca.length;
  bool get isLoaded => _isLoaded;

  // ── Load & Save Deleted IDs from Local Storage ──────────────
  Future<void> _loadDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('deleted_notification_ids') ?? [];
      _deletedIds.clear();
      _deletedIds.addAll(list);
    } catch (e) {
      debugPrint("Error loading deleted notification ids: $e");
    }
  }

  Future<void> _saveDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('deleted_notification_ids', _deletedIds.toList());
    } catch (e) {
      debugPrint("Error saving deleted notification ids: $e");
    }
  }

  // ── Fetch dari server ─────────────────────────────────────

  Future<void> loadNotifikasi({bool forceRefresh = false}) async {
    if (_isFetching) return;
    
    // 1. Ambil data dari cache lokal terlebih dahulu (Local-First Read)
    if (_list.isEmpty || forceRefresh) {
      await _loadDeletedIds();
      final localData = await OfflineDatabaseService().ambilNotifikasi();
      if (localData.isNotEmpty) {
        _list.clear();
        final items = localData
            .map((e) => NotifikasiItem.fromJson(e))
            .where((n) => !_deletedIds.contains(n.id))
            .toList();
        _list.addAll(items);
        _isLoaded = true;
        notifyListeners();
      }
    }

    if (_isLoaded && !forceRefresh) return;

    _isFetching = true;

    final token = AuthService().token;
    if (token == null) {
      _isLoaded = true;
      _isFetching = false;
      notifyListeners();
      return;
    }

    await _loadDeletedIds();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifikasi');
      final response = await http
          .get(url, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final List rawList = body['data'] as List;
          
          _list.clear();
          final List<Map<String, dynamic>> cacheList = [];

          final items = rawList
              .map((e) {
                if (e is Map<String, dynamic>) {
                  cacheList.add(e);
                  return NotifikasiItem.fromJson(e);
                }
                return NotifikasiItem.fromJson(Map<String, dynamic>.from(e));
              })
              .where((n) => !_deletedIds.contains(n.id))
              .toList();

          _list.addAll(items);

          // 2. Deteksi notifikasi baru & trigger getaran + bunyi
          if (_knownIds.isNotEmpty) {
            // Hanya trigger jika ini bukan load pertama (agar tidak berbunyi tiap buka app)
            final newItems = items
                .where((n) => !_knownIds.contains(n.id))
                .toList();
            if (newItems.isNotEmpty) {
              // Ambil notifikasi terbaru sebagai representasi alert
              final newest = newItems.first;
              AlertService().triggerNewNotificationAlert(
                judul: newest.judul,
                pesan: newest.pesan,
                ikon: newest.ikon,
              );
              debugPrint('NotifikasiService: ${newItems.length} notif baru -> alert dipicu');
            }
          }
          // Update known IDs dengan semua ID yang ada sekarang
          _knownIds.clear();
          _knownIds.addAll(items.map((n) => n.id));

          // 3. Simpan ke database lokal (Update Cache)
          await OfflineDatabaseService().simpanNotifikasi(cacheList);
        }
      }
    } catch (e) {
      debugPrint('ERROR fetchNotifikasi: $e');
    } finally {
      _isLoaded = true;
      _isFetching = false;
      notifyListeners();
    }
  }

  // ── Tandai satu notifikasi dibaca (kirim ke server) ───────

  Future<void> tandaiDibaca(String id) async {
    final index = _list.indexWhere((n) => n.id == id);
    if (index != -1) {
      _list[index].sudahDibaca = true;
      notifyListeners();
    }

    final token = AuthService().token;
    if (token == null) return;

    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifikasi/$id/read'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('ERROR markRead: $e');
    }
  }

  // ── Tandai SEMUA dibaca ───────────────────────────────────

  Future<void> tandaiSemuaDibaca() async {
    for (final n in _list) {
      n.sudahDibaca = true;
    }
    notifyListeners();

    final token = AuthService().token;
    if (token == null) return;

    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifikasi/all/read'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('ERROR markAllRead: $e');
    }
  }

  // ── Hapus lokal (hanya UI, server tidak dihapus) ──────────

  Future<void> hapusNotifikasi(String id) async {
    _deletedIds.add(id);
    _list.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveDeletedIds();
  }

  // ── Periodic Polling ──────────────────────────────────────

  void startPeriodicFetch({int intervalSeconds = 10}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      loadNotifikasi(forceRefresh: true);
    });
    // Trigger an immediate fetch as well
    loadNotifikasi(forceRefresh: true);
  }

  void stopPeriodicFetch() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // ── Reset (saat logout) ───────────────────────────────────

  void reset() {
    stopPeriodicFetch();
    _list.clear();
    _knownIds.clear();
    _isLoaded = false;
    _isFetching = false;
    notifyListeners();
  }

  // ── Helper ────────────────────────────────────────────────

  NotifikasiItem? getById(String id) {
    try {
      return _list.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}
