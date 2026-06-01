import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import '../models/pengajuan_model.dart';
import './auth_service.dart';
import './offline_database_service.dart';

// ============================================================
//  SERVICE — State Management Pengajuan & Notifikasi
//  Terintegrasi dengan Backend Laravel
// ============================================================

class PengajuanService extends ChangeNotifier {
  // Singleton
  static final PengajuanService _instance = PengajuanService._internal();
  factory PengajuanService() => _instance;
  PengajuanService._internal();

  final List<PengajuanSurat> _daftarPengajuan = [];
  final List<NotifikasiItem> _notifikasi = [];

  List<PengajuanSurat> get daftarPengajuan =>
      List.unmodifiable(_daftarPengajuan);
  List<NotifikasiItem> get notifikasi => List.unmodifiable(_notifikasi);

  int get jumlahBelumDibaca =>
      _notifikasi.where((n) => !n.sudahDibaca).length;

  // ── Sinkronisasi dengan Backend (API Fetch) ─────────────
  Future<List<PengajuanSurat>> muatDaftarPengajuan() async {
    final token = AuthService().token;
    if (token == null) return _daftarPengajuan;

    // 1. Ambil data dari cache lokal & antrean offline (Local-First Read)
    final localData = await OfflineDatabaseService().ambilPengajuan();
    final queue = await OfflineDatabaseService().ambilSyncQueue();
    final pendingItems = queue
        .where((item) => item['action'] == 'tambah_pengajuan')
        .map((item) {
          final payload = Map<String, dynamic>.from(item['payload']);
          final localFormRaw = payload['local_form_data'] ?? {};
          final Map<String, String> localFormData = {};
          if (localFormRaw is Map) {
            localFormRaw.forEach((k, v) {
              localFormData[k.toString()] = v?.toString() ?? '';
            });
          }

          return PengajuanSurat(
            id: item['id']?.toString() ?? 'PGJ-PENDING-${DateTime.now().millisecondsSinceEpoch}',
            jenisSurat: payload['jenis_surat_nama']?.toString() ?? 'Pengajuan Surat',
            emoji: payload['emoji']?.toString() ?? '📝',
            data: localFormData,
            tanggalAjuan: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
            status: StatusPengajuan.menunggu,
            alasanTolak: 'Menunggu sinkronisasi internet... 🔄',
          );
        })
        .toList();

    _daftarPengajuan.clear();
    _daftarPengajuan.addAll(pendingItems); // Tampilkan item pending di paling atas

    if (localData.isNotEmpty) {
      _daftarPengajuan.addAll(
        localData.map((item) => PengajuanSurat.fromJson(item)).toList(),
      );
    }
    notifyListeners();

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/surat");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final List rawList = responseData['data'];
          
          final List<Map<String, dynamic>> cacheList = [];
          _daftarPengajuan.clear();
          _daftarPengajuan.addAll(pendingItems); // Tetap pertahankan item pending di atas
          
          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              _daftarPengajuan.add(PengajuanSurat.fromJson(item));
              cacheList.add(item);
            }
          }
          
          // 2. Simpan data terbaru ke cache
          await OfflineDatabaseService().simpanPengajuan(cacheList);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("ERROR muatDaftarPengajuan: $e");
    }
    return _daftarPengajuan;
  }

  // ── Tambah Pengajuan Baru ──────────────────────────────
  // (Tetap dipertahankan untuk kompatibilitas offline responsif)
  PengajuanSurat tambahPengajuan({
    required String jenisSurat,
    required String emoji,
    required Map<String, String> data,
  }) {
    final pengajuan = PengajuanSurat(
      id: 'PGJ-${DateTime.now().millisecondsSinceEpoch}',
      jenisSurat: jenisSurat,
      emoji: emoji,
      data: data,
      tanggalAjuan: DateTime.now(),
    );
    _daftarPengajuan.insert(0, pengajuan);
    
    // Update cache lokal
    _updateLocalCache();
    
    notifyListeners();
    return pengajuan;
  }

  /// Tambah pengajuan secara offline dan simpan ke sync queue
  Future<void> tambahPengajuanOffline({
    required String jenisSuratId,
    required String jenisSuratNama,
    required String emoji,
    required Map<String, dynamic> answers,
    required Map<String, String> localFormData,
  }) async {
    // 1. Simpan ke sync queue
    await OfflineDatabaseService().tambahKeSyncQueue(
      action: 'tambah_pengajuan',
      payload: {
        'jenis_surat_id': jenisSuratId,
        'jenis_surat_nama': jenisSuratNama,
        'emoji': emoji,
        'answers': answers,
        'local_form_data': localFormData,
      },
    );

    // 2. Tambah item sementara ke list memori agar langsung tampil
    final pengajuan = PengajuanSurat(
      id: 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
      jenisSurat: jenisSuratNama,
      emoji: emoji,
      data: localFormData,
      tanggalAjuan: DateTime.now(),
      status: StatusPengajuan.menunggu,
      alasanTolak: 'Menunggu sinkronisasi internet... 🔄',
    );
    _daftarPengajuan.insert(0, pengajuan);
    notifyListeners();
  }

  Future<void> _updateLocalCache() async {
    final cacheData = _daftarPengajuan
        .where((p) => !p.id.startsWith('SYNC-'))
        .map((p) => p.toJson())
        .toList();
    await OfflineDatabaseService().simpanPengajuan(cacheData);
  }

  // ── Admin: Approve ─────────────────────────────────────
  void approvePengajuan(String id) {
    final index = _daftarPengajuan.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final pengajuan = _daftarPengajuan[index];
    pengajuan.status = StatusPengajuan.disetujui;
    pengajuan.tanggalRespons = DateTime.now();

    _tambahNotifikasi(
      judul: 'Surat Disetujui! ✅',
      pesan:
          'Pengajuan ${pengajuan.jenisSurat} Anda telah disetujui. Silakan unduh file PDF surat Anda.',
      jenis: JenisNotifikasi.disetujui,
      pengajuanId: id,
    );

    notifyListeners();
  }

  // ── Admin: Tolak ───────────────────────────────────────
  void tolakPengajuan(String id, String alasan) {
    final index = _daftarPengajuan.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final pengajuan = _daftarPengajuan[index];
    pengajuan.status = StatusPengajuan.ditolak;
    pengajuan.alasanTolak = alasan;
    pengajuan.tanggalRespons = DateTime.now();

    _tambahNotifikasi(
      judul: 'Pengajuan Ditolak ❌',
      pesan:
          'Pengajuan ${pengajuan.jenisSurat} Anda ditolak. Alasan: $alasan',
      jenis: JenisNotifikasi.ditolak,
      pengajuanId: id,
    );

    notifyListeners();
  }

  // ── Tandai Notifikasi Sudah Dibaca ─────────────────────
  void bacaNotifikasi(String id) {
    final index = _notifikasi.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifikasi[index].sudahDibaca = true;
    notifyListeners();
  }

  void bacaSemuaNotifikasi() {
    for (final n in _notifikasi) {
      n.sudahDibaca = true;
    }
    notifyListeners();
  }

  // ── Private: Tambah Notifikasi ─────────────────────────
  void _tambahNotifikasi({
    required String judul,
    required String pesan,
    required JenisNotifikasi jenis,
    String? pengajuanId,
  }) {
    _notifikasi.insert(
      0,
      NotifikasiItem(
        id: 'NTF-${DateTime.now().millisecondsSinceEpoch}',
        judul: judul,
        pesan: pesan,
        jenis: jenis,
        waktu: DateTime.now(),
        pengajuanId: pengajuanId,
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────────
  PengajuanSurat? getPengajuanById(String id) {
    try {
      return _daftarPengajuan.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}