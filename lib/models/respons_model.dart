// ============================================================
//  MODEL RESPONS ADMIN
// ============================================================

enum TipeRespons { pengajuan, pengaduan }

class ResponsAdmin {
  final String id;
  final String idPengajuan; // id dari pengajuan atau pengaduan
  final TipeRespons tipe; // tipe respons (pengajuan/pengaduan)
  final String pesan; // pesan respons dari admin
  final DateTime tanggalRespons;
  final String adminNama;
  final String? adminId;

  ResponsAdmin({
    required this.id,
    required this.idPengajuan,
    required this.tipe,
    required this.pesan,
    required this.tanggalRespons,
    required this.adminNama,
    this.adminId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_pengajuan': idPengajuan,
      'tipe': tipe == TipeRespons.pengajuan ? 'pengajuan' : 'pengaduan',
      'pesan': pesan,
      'tanggal_respons': tanggalRespons.toIso8601String(),
      'admin_nama': adminNama,
      'admin_id': adminId,
    };
  }

  factory ResponsAdmin.fromJson(Map<String, dynamic> json) {
    return ResponsAdmin(
      id: json['id']?.toString() ?? '',
      idPengajuan: json['id_pengajuan']?.toString() ?? json['idPengajuan']?.toString() ?? '',
      tipe: json['tipe']?.toString().toLowerCase() == 'pengajuan'
          ? TipeRespons.pengajuan
          : TipeRespons.pengaduan,
      pesan: json['pesan'] ?? '',
      tanggalRespons: json['tanggal_respons'] != null
          ? DateTime.parse(json['tanggal_respons'].toString())
          : DateTime.now(),
      adminNama: json['admin_nama'] ?? json['adminNama'] ?? 'Admin',
      adminId: json['admin_id']?.toString() ?? json['adminId']?.toString(),
    );
  }
}

// ============================================================
//  MODEL NOTIFIKASI
// ============================================================

enum TipeNotifikasi { pengajuanBaru, pengaduanBaru, respons, disetujui, ditolak }

class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final TipeNotifikasi tipe;
  final DateTime waktu;
  bool sudahDibaca;
  final String? relatedId; // id dari pengajuan/pengaduan/respons

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.waktu,
    this.sudahDibaca = false,
    this.relatedId,
  });

  String get ikon {
    switch (tipe) {
      case TipeNotifikasi.pengajuanBaru:
        return '📄';
      case TipeNotifikasi.pengaduanBaru:
        return '🚨';
      case TipeNotifikasi.respons:
        return '💬';
      case TipeNotifikasi.disetujui:
        return '✅';
      case TipeNotifikasi.ditolak:
        return '❌';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe.toString().split('.').last,
      'waktu': waktu.toIso8601String(),
      'sudah_dibaca': sudahDibaca,
      'related_id': relatedId,
    };
  }

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      id: json['id']?.toString() ?? '',
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      tipe: _getTipeNotifikasi(json['tipe']?.toString()),
      waktu: json['waktu'] != null
          ? DateTime.parse(json['waktu'].toString())
          : DateTime.now(),
      sudahDibaca: json['sudah_dibaca'] == true,
      relatedId: json['related_id']?.toString(),
    );
  }
}

TipeNotifikasi _getTipeNotifikasi(String? tipe) {
  switch (tipe?.toLowerCase()) {
    case 'pengajuanbaru':
      return TipeNotifikasi.pengajuanBaru;
    case 'pengaduanbaru':
      return TipeNotifikasi.pengaduanBaru;
    case 'respons':
      return TipeNotifikasi.respons;
    case 'disetujui':
      return TipeNotifikasi.disetujui;
    case 'ditolak':
      return TipeNotifikasi.ditolak;
    default:
      return TipeNotifikasi.respons;
  }
}
