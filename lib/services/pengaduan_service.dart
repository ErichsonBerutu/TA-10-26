// lib/services/pengaduan_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config/api_config.dart';
import '../models/pengaduan_model.dart';
import 'auth_service.dart';

class PengaduanService extends ChangeNotifier {
  static final PengaduanService _instance = PengaduanService._internal();
  factory PengaduanService() => _instance;
  PengaduanService._internal();

  static String get baseUrl => ApiConfig.baseUrl;

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

  Future<String?> _getAuthToken() async {
    final authService = AuthService();
    if (authService.token != null) {
      return authService.token;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> muatRiwayatPengaduan() async {
    final token = await _getAuthToken();
    if (token == null) {
      return false;
    }

    final url = Uri.parse('$baseUrl/pengaduan');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return false;
      }

      final body = jsonDecode(response.body);
      final rawList = body is List
          ? body
          : body['data'] ?? body['pengaduan'] ?? [];

      if (rawList is! List) {
        return false;
      }

      _list.clear();
      _list.addAll(
        rawList.map((item) {
          if (item is Map<String, dynamic>) {
            return PengaduanItem.fromJson(item);
          }
          return PengaduanItem.fromJson(
            Map<String, dynamic>.from(item),
          );
        }).toList(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ERROR muatRiwayatPengaduan: $e');
      return false;
    }
  }

  Future<bool> kirimPengaduan({
    required String judul,
    required String deskripsi,
    required JenisPengaduan jenis,
    String? fotoPath,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return false;
    }

    final uri = Uri.parse('$baseUrl/pengaduan');

    try {
      http.Response response;

      if (fotoPath != null && fotoPath.isNotEmpty) {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          })
          ..fields['judul'] = judul
          ..fields['deskripsi'] = deskripsi
          ..fields['jenis'] = PengaduanItem.jenisToString(jenis);

        try {
          request.files.add(await http.MultipartFile.fromPath('foto', fotoPath));
        } catch (e) {
          debugPrint('Unable to attach foto: $e');
        }

        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'judul': judul,
            'deskripsi': deskripsi,
            'jenis': PengaduanItem.jenisToString(jenis),
          }),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      final data = jsonDecode(response.body);
      final payload = data is Map<String, dynamic>
          ? data['data'] ?? data['pengaduan'] ?? data
          : data;

      if (payload is Map<String, dynamic>) {
        _list.insert(0, PengaduanItem.fromJson(payload));
      } else {
        _list.insert(
          0,
          PengaduanItem(
            id: 'PDG-${DateTime.now().millisecondsSinceEpoch}',
            judul: judul,
            deskripsi: deskripsi,
            jenis: jenis,
            tanggalAjuan: DateTime.now(),
            fotoPath: fotoPath,
          ),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ERROR kirimPengaduan: $e');
      return false;
    }
  }

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
    if (i != -1) {
      _list[i].status = StatusPengaduan.diproses;
      _list[i].tanggalRespons = DateTime.now();
      notifyListeners();
    }
  }

  void selesaikanPengaduan(String id, {String? catatan}) {
    final i = _list.indexWhere((p) => p.id == id);
    if (i != -1) {
      _list[i].status = StatusPengaduan.selesai;
      _list[i].catatanAdmin = catatan;
      _list[i].tanggalRespons = DateTime.now();
      notifyListeners();
    }
  }

  void tolakPengaduan(String id, {String? catatan}) {
    final i = _list.indexWhere((p) => p.id == id);
    if (i != -1) {
      _list[i].status = StatusPengaduan.ditolak;
      _list[i].catatanAdmin = catatan;
      _list[i].tanggalRespons = DateTime.now();
      notifyListeners();
    }
  }

  PengaduanItem? getPengaduanById(String id) {
    try {
      return _list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
