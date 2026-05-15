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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'jenis': jenisToString(jenis),
      'tanggal_ajuan': tanggalAjuan.toIso8601String(),
      'foto': fotoPath,
      'status': statusToString(status),
      'catatan_admin': catatanAdmin,
      'tanggal_respons': tanggalRespons?.toIso8601String(),
    };
  }

  factory PengaduanItem.fromJson(Map<String, dynamic> json) {
    final jenisString = json['jenis']?.toString();
    final statusString = json['status']?.toString();

    return PengaduanItem(
      id: json['id']?.toString() ?? '',
      judul: json['judul'] ?? json['title'] ?? '',
      deskripsi: json['deskripsi'] ?? json['description'] ?? '',
      jenis: _jenisFromString(jenisString ?? ''),
      tanggalAjuan: DateTime.tryParse(
            json['tanggal_ajuan']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      fotoPath: json['foto_url']?.toString() ??
          json['foto']?.toString() ??
          json['foto_path']?.toString(),
      status: _statusFromString(statusString ?? ''),
      catatanAdmin: json['catatan_admin']?.toString(),
      tanggalRespons: DateTime.tryParse(
        json['tanggal_respons']?.toString() ??
            json['updated_at']?.toString() ??
            '',
      ),
    );
  }

  static JenisPengaduan _jenisFromString(String value) {
    switch (value.toLowerCase()) {
      case 'infrastruktur':
        return JenisPengaduan.infrastruktur;
      case 'pelayanan':
        return JenisPengaduan.pelayanan;
      case 'keamanan':
        return JenisPengaduan.keamanan;
      case 'lingkungan':
        return JenisPengaduan.lingkungan;
      default:
        return JenisPengaduan.infrastruktur;
    }
  }

  static StatusPengaduan _statusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'diproses':
        return StatusPengaduan.diproses;
      case 'selesai':
        return StatusPengaduan.selesai;
      case 'ditolak':
        return StatusPengaduan.ditolak;
      case 'menunggu':
      default:
        return StatusPengaduan.menunggu;
    }
  }

  static String jenisToString(JenisPengaduan jenis) {
    switch (jenis) {
      case JenisPengaduan.infrastruktur:
        return 'infrastruktur';
      case JenisPengaduan.pelayanan:
        return 'pelayanan';
      case JenisPengaduan.keamanan:
        return 'keamanan';
      case JenisPengaduan.lingkungan:
        return 'lingkungan';
    }
  }

  static String statusToString(StatusPengaduan status) {
    switch (status) {
      case StatusPengaduan.menunggu:
        return 'menunggu';
      case StatusPengaduan.diproses:
        return 'diproses';
      case StatusPengaduan.selesai:
        return 'selesai';
      case StatusPengaduan.ditolak:
        return 'ditolak';
    }
  }

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