import 'dart:convert';

// ============================================================
//  MODEL PENGAJUAN SURAT
// ============================================================

enum StatusPengajuan { menunggu, diproses, disetujui, ditolak }

class PengajuanSurat {
  final String id;
  final String jenisSurat;
  final String emoji;
  final Map<String, String> data;
  final DateTime tanggalAjuan;
  StatusPengajuan status;
  String? alasanTolak;
  DateTime? tanggalRespons;
  String? nomorSurat;
  String? filePdf;

  PengajuanSurat({
    required this.id,
    required this.jenisSurat,
    required this.emoji,
    required this.data,
    required this.tanggalAjuan,
    this.status = StatusPengajuan.menunggu,
    this.alasanTolak,
    this.tanggalRespons,
    this.nomorSurat,
    this.filePdf,
  });

  String get statusLabel {
    switch (status) {
      case StatusPengajuan.menunggu:
        return 'Menunggu';
      case StatusPengajuan.diproses:
        return 'Diproses';
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
      case StatusPengajuan.diproses:
        return '🔄';
      case StatusPengajuan.disetujui:
        return '✅';
      case StatusPengajuan.ditolak:
        return '❌';
    }
  }

  factory PengajuanSurat.fromJson(Map<String, dynamic> json) {
    StatusPengajuan statusEnum;
    final dbStatus = json['status']?.toString().toLowerCase() ?? 'diajukan';
    if (dbStatus == 'selesai') {
      statusEnum = StatusPengajuan.disetujui;
    } else if (dbStatus == 'ditolak') {
      statusEnum = StatusPengajuan.ditolak;
    } else if (dbStatus == 'diproses') {
      statusEnum = StatusPengajuan.diproses;
    } else {
      // 'diajukan', 'pending', atau status lainnya → menunggu
      statusEnum = StatusPengajuan.menunggu;
    }

    Map<String, String> parsedData = {};
    var rawDataForm = json['data_form'];
    if (rawDataForm != null) {
      try {
        Map<String, dynamic> rawMap = {};
        if (rawDataForm is String) {
          rawMap = Map<String, dynamic>.from(jsonDecode(rawDataForm));
        } else if (rawDataForm is Map) {
          rawMap = Map<String, dynamic>.from(rawDataForm);
        }
        rawMap.forEach((key, value) {
          parsedData[key] = value?.toString() ?? '';
        });
      } catch (e) {
        print('Error decoding data_form: $e');
      }
    }

    String rawJenisSurat = 'Pengajuan Surat';
    String rawEmoji = '📝';
    if (json['jenis_surat'] != null) {
      rawJenisSurat = json['jenis_surat']['nama_surat']?.toString() ?? 'Pengajuan Surat';
      rawEmoji = _getEmojiForSurat(rawJenisSurat);
    }

    return PengajuanSurat(
      id: json['id_pengajuan_surat']?.toString() ?? '',
      jenisSurat: rawJenisSurat,
      emoji: rawEmoji,
      data: parsedData,
      tanggalAjuan: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      status: statusEnum,
      alasanTolak: json['alasan_tolak']?.toString(),
      tanggalRespons: json['tanggal_respons'] != null
          ? DateTime.tryParse(json['tanggal_respons'])
          : null,
      nomorSurat: json['nomor_surat']?.toString(),
      filePdf: json['file_pdf']?.toString(),
    );
  }

  static String _getEmojiForSurat(String namaSurat) {
    final lower = namaSurat.toLowerCase();
    if (lower.contains('domisili')) return '🏠';
    if (lower.contains('usaha')) return '💼';
    if (lower.contains('nikah') || lower.contains('pernikahan')) return '💍';
    if (lower.contains('kematian') || lower.contains('meninggal')) return '⚰️';
    if (lower.contains('lahir') || lower.contains('kelahiran')) return '👶';
    if (lower.contains('miskin') || lower.contains('sktm')) return '🎟️';
    if (lower.contains('kelakuan baik') || lower.contains('skck')) return '👮';
    return '📝';
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