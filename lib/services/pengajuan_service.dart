import 'package:flutter/material.dart';
import '../models/pengajuan_model.dart';

// ============================================================
//  SERVICE — State Management Pengajuan & Notifikasi
//  Gunakan dengan InheritedWidget atau Provider
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

  // ── Tambah Pengajuan Baru ──────────────────────────────

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