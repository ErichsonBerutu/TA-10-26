import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import '../models/pengajuan_model.dart';
import './auth_service.dart';

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

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/surat");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final List rawList = responseData['data'];
          
          _daftarPengajuan.clear();
          for (var item in rawList) {
            _daftarPengajuan.add(PengajuanSurat.fromJson(item));
          }
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
    notifyListeners();
    return pengajuan;
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