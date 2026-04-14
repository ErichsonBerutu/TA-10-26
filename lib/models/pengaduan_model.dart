// lib/models/pengaduan_model.dart

enum StatusPengaduan { menunggu, diproses, selesai, ditolak }

enum JenisPengaduan { infrastruktur, pelayanan, keamanan, lingkungan }

class PengaduanItem {
  final String id;
  final String judul;
  final String deskripsi;
  final JenisPengaduan jenis;
  final DateTime tanggalAjuan;
  final String? fotoPath;        
  StatusPengaduan status;
  String? catatanAdmin;
  DateTime? tanggalRespons;

  PengaduanItem({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.jenis,
    required this.tanggalAjuan,
    this.fotoPath,
    this.status = StatusPengaduan.menunggu,
    this.catatanAdmin,
    this.tanggalRespons,
  });

  String get jenisLabel {
    switch (jenis) {
      case JenisPengaduan.infrastruktur: return 'Infrastruktur';
      case JenisPengaduan.pelayanan:     return 'Pelayanan Publik';
      case JenisPengaduan.keamanan:      return 'Keamanan & Ketertiban';
      case JenisPengaduan.lingkungan:    return 'Lingkungan Hidup';
    }
  }

  String get jenisEmoji {
    switch (jenis) {
      case JenisPengaduan.infrastruktur: return '🏗️';
      case JenisPengaduan.pelayanan:     return '🏛️';
      case JenisPengaduan.keamanan:      return '🛡️';
      case JenisPengaduan.lingkungan:    return '🌿';
    }
  }

  String get statusLabel {
    switch (status) {
      case StatusPengaduan.menunggu: return 'Menunggu';
      case StatusPengaduan.diproses: return 'Diproses';
      case StatusPengaduan.selesai:  return 'Selesai';
      case StatusPengaduan.ditolak:  return 'Ditolak';
    }
  }

  String get statusEmoji {
    switch (status) {
      case StatusPengaduan.menunggu: return '⏳';
      case StatusPengaduan.diproses: return '🔄';
      case StatusPengaduan.selesai:  return '✅';
      case StatusPengaduan.ditolak:  return '❌';
    }
  }
}