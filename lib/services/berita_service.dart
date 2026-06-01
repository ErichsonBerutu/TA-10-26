// lib/services/berita_service.dart
//
// Service untuk mengambil data berita desa dari API backend.
// Endpoint: GET /api/berita (public, tidak perlu auth)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import './offline_database_service.dart';

// ============================================================
//  MODEL BERITA (Real dari API)
// ============================================================

class BeritaItem {
  final String idBerita;
  final String judul;
  final String deskripsi;
  final String? gambar;
  final String? gambarUrl;
  final String? idDibuatOleh;
  final DateTime createdAt;
  final bool hasTimestamp;

  const BeritaItem({
    required this.idBerita,
    required this.judul,
    required this.deskripsi,
    this.gambar,
    this.gambarUrl,
    this.idDibuatOleh,
    required this.createdAt,
    this.hasTimestamp = false,
  });

  factory BeritaItem.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'];
    final parsedCreatedAt = rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt.toString()) : null;
    return BeritaItem(
      idBerita: json['id_berita']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      gambar: json['gambar']?.toString(),
      gambarUrl: json['gambar_url']?.toString(),
      idDibuatOleh: json['id_dibuat_oleh']?.toString(),
      createdAt: parsedCreatedAt ?? DateTime.now(),
      hasTimestamp: parsedCreatedAt != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_berita': idBerita,
      'judul': judul,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'gambar_url': gambarUrl,
      'id_dibuat_oleh': idDibuatOleh,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ============================================================
//  SERVICE
// ============================================================

class BeritaService extends ChangeNotifier {
  // Singleton
  static final BeritaService _instance = BeritaService._internal();
  factory BeritaService() => _instance;
  BeritaService._internal();

  final List<BeritaItem> _daftar = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<BeritaItem> get daftar => List.unmodifiable(_daftar);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int get total => _daftar.length;

  /// Muat data berita dari server.
  /// Endpoint publik — tidak perlu token auth.
  Future<void> muatBerita({bool forceRefresh = false}) async {
    // 1. Ambil dari database lokal terlebih dahulu (Local-First Read)
    if (_daftar.isEmpty || forceRefresh) {
      final localData = await OfflineDatabaseService().ambilBerita();
      if (localData.isNotEmpty) {
        _daftar.clear();
        for (final item in localData) {
          _daftar.add(BeritaItem.fromJson(item));
        }
        notifyListeners();
      }
    }

    // Jika sudah ada data di memori dan tidak dipaksa refresh, skip pemanggilan jaringan
    if (_daftar.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/berita');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final List rawList = body['data'] as List;
          
          _daftar.clear();
          final List<Map<String, dynamic>> cacheList = [];
          
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              _daftar.add(BeritaItem.fromJson(item));
              cacheList.add(item);
            }
          }
          
          // 2. Simpan hasil fetch ke database lokal (Update Cache)
          await OfflineDatabaseService().simpanBerita(cacheList);
          _hasError = false;
        }
      } else {
        if (_daftar.isEmpty) {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        }
      }
    } catch (e) {
      debugPrint('ERROR muatBerita: $e');
      if (_daftar.isEmpty) {
        _hasError = true;
        _errorMessage = 'Gagal memuat berita. Periksa koneksi internet.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
