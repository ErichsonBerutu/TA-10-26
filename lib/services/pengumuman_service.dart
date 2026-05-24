// lib/services/pengumuman_service.dart
//
// Service untuk mengambil data pengumuman desa dari API backend.
// Endpoint: GET /api/pengumuman (public, tidak perlu auth)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';

// ============================================================
//  MODEL PENGUMUMAN (Real dari API)
// ============================================================

class PengumumanItem {
  final String id;
  final String judul;
  final String isi;
  final String? gambarUrl;
  final String namaPembuat;
  final DateTime createdAt;

  const PengumumanItem({
    required this.id,
    required this.judul,
    required this.isi,
    this.gambarUrl,
    required this.namaPembuat,
    required this.createdAt,
  });

  factory PengumumanItem.fromJson(Map<String, dynamic> json) {
    return PengumumanItem(
      id: json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      gambarUrl: json['gambar_url']?.toString(),
      namaPembuat: json['nama_pembuat']?.toString() ?? 'Admin Desa',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ============================================================
//  SERVICE
// ============================================================

class PengumumanService extends ChangeNotifier {
  // Singleton
  static final PengumumanService _instance = PengumumanService._internal();
  factory PengumumanService() => _instance;
  PengumumanService._internal();

  final List<PengumumanItem> _daftar = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<PengumumanItem> get daftar => List.unmodifiable(_daftar);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int get total => _daftar.length;

  /// Muat data pengumuman dari server.
  /// Endpoint publik — tidak perlu token auth.
  Future<void> muatPengumuman({bool forceRefresh = false}) async {
    // Jika sudah ada data dan tidak force refresh, skip
    if (_daftar.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/pengumuman');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final List rawList = body['data'] as List;
          _daftar.clear();
          for (final item in rawList) {
            _daftar.add(PengumumanItem.fromJson(item as Map<String, dynamic>));
          }
        }
      } else {
        _hasError = true;
        _errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Gagal memuat pengumuman. Periksa koneksi internet.';
      debugPrint('ERROR muatPengumuman: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
