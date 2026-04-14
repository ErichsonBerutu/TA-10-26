// lib/services/pengaduan_service.dart

import 'package:flutter/foundation.dart';
import '../models/pengaduan_model.dart';

class PengaduanService extends ChangeNotifier {
  static final PengaduanService _instance = PengaduanService._internal();
  factory PengaduanService() => _instance;
  PengaduanService._internal();

  final List<PengaduanItem> _list = [];

  List<PengaduanItem> get daftarPengaduan => List.unmodifiable(_list);
  List<PengaduanItem> get menunggu => _list.where((p) => p.status == StatusPengaduan.menunggu).toList();
  List<PengaduanItem> get diproses => _list.where((p) => p.status == StatusPengaduan.diproses).toList();
  List<PengaduanItem> get selesai  => _list.where((p) => p.status == StatusPengaduan.selesai).toList();
  List<PengaduanItem> get ditolak  => _list.where((p) => p.status == StatusPengaduan.ditolak).toList();

  int get totalPengaduan => _list.length;
  int get jumlahMenunggu => menunggu.length;
  int get jumlahDiproses => diproses.length;
  int get jumlahSelesai  => selesai.length;
  int get jumlahDitolak  => ditolak.length;

  void tambahPengaduan({
    required String judul,
    required String deskripsi,
    required JenisPengaduan jenis,
    String? fotoPath,
  }) {
    _list.insert(0, PengaduanItem(
      id: 'PDG-${DateTime.now().millisecondsSinceEpoch}',
      judul: judul,
      deskripsi: deskripsi,
      jenis: jenis,
      tanggalAjuan: DateTime.now(),
      fotoPath: fotoPath,
    ));
    notifyListeners();
  }

  void proseskanPengaduan(String id) {
    final i = _list.indexWhere((p) => p.id == id);
    if (i != -1) { _list[i].status = StatusPengaduan.diproses; _list[i].tanggalRespons = DateTime.now(); notifyListeners(); }
  }

  void selesaikanPengaduan(String id, {String? catatan}) {
    final i = _list.indexWhere((p) => p.id == id);
    if (i != -1) { _list[i].status = StatusPengaduan.selesai; _list[i].catatanAdmin = catatan; _list[i].tanggalRespons = DateTime.now(); notifyListeners(); }
  }

  void tolakPengaduan(String id, {String? catatan}) {
    final i = _list.indexWhere((p) => p.id == id);
    if (i != -1) { _list[i].status = StatusPengaduan.ditolak; _list[i].catatanAdmin = catatan; _list[i].tanggalRespons = DateTime.now(); notifyListeners(); }
  }

  PengaduanItem? getPengaduanById(String id) {
    try { return _list.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
}