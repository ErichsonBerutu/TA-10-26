// ============================================================
//  MODEL PENGAJUAN SURAT
// ============================================================

enum StatusPengajuan { menunggu, disetujui, ditolak }

class PengajuanSurat {
  final String id;
  final String jenisSurat;
  final String emoji;
  final Map<String, String> data;
  final DateTime tanggalAjuan;
  StatusPengajuan status;
  String? alasanTolak;
  DateTime? tanggalRespons;

  PengajuanSurat({
    required this.id,
    required this.jenisSurat,
    required this.emoji,
    required this.data,
    required this.tanggalAjuan,
    this.status = StatusPengajuan.menunggu,
    this.alasanTolak,
    this.tanggalRespons,
  });

  String get statusLabel {
    switch (status) {
      case StatusPengajuan.menunggu:
        return 'Menunggu';
      case StatusPengajuan.disetujui:
        return 'Disetujui';
      case StatusPengajuan.ditolak:
        return 'Ditolak';
    }
  }

  String get statusEmoji {
    switch (status) {
      case StatusPengajuan.menunggu:
        return '⏳';
      case StatusPengajuan.disetujui:
        return '✅';
      case StatusPengajuan.ditolak:
        return '❌';
    }
  }
}

// ============================================================
//  MODEL NOTIFIKASI
// ============================================================

enum JenisNotifikasi { disetujui, ditolak, info }

class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final JenisNotifikasi jenis;
  final DateTime waktu;
  bool sudahDibaca;
  final String? pengajuanId;

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.jenis,
    required this.waktu,
    this.sudahDibaca = false,
    this.pengajuanId,
  });
}