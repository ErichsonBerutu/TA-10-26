// lib/services/respons_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config/api_config.dart';
import '../models/respons_model.dart';
import 'auth_service.dart';

// ============================================================
//  SERVICE — Respons Admin (untuk reply pengajuan & pengaduan)
//  Mengelola pengiriman respons dan menerima respons dari server
// ============================================================

class ResponsService extends ChangeNotifier {
  // Singleton
  static final ResponsService _instance = ResponsService._internal();
  factory ResponsService() => _instance;
  ResponsService._internal();

  static String get baseUrl => ApiConfig.baseUrl;

  final List<ResponsAdmin> _respons = [];

  List<ResponsAdmin> get respons => List.unmodifiable(_respons);

  Future<String?> _getAuthToken() async {
    final authService = AuthService();
    if (authService.token != null) {
      return authService.token;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ── Load Respons untuk Pengajuan/Pengaduan ─────────────

  Future<List<ResponsAdmin>> muatRespons({
    required String idPengajuan,
    required TipeRespons tipe,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return [];
    }

    final typeString = tipe == TipeRespons.pengajuan ? 'pengajuan' : 'pengaduan';
    final url = Uri.parse('$baseUrl/respons/$typeString/$idPengajuan');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawList = body is List
            ? body
            : body['data'] ?? body['respons'] ?? [];

        if (rawList is! List) {
          return [];
        }

        final responsItems = rawList
            .map((item) => ResponsAdmin.fromJson(item as Map<String, dynamic>))
            .toList();

        // Simpan ke cache
        _cacheSimpanRespons(idPengajuan, responsItems);

        return responsItems;
      } else {
        // Coba ambil dari cache
        return _cacheAmbilRespons(idPengajuan);
      }
    } catch (e) {
      debugPrint('ERROR muatRespons: $e');
      // Coba ambil dari cache jika terjadi error
      return _cacheAmbilRespons(idPengajuan);
    }
  }

  // ── Kirim Respons ke Server ────────────────────────────

  Future<bool> kirimRespons({
    required String idPengajuan,
    required TipeRespons tipe,
    required String pesan,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return false;
    }

    final typeString = tipe == TipeRespons.pengajuan ? 'pengajuan' : 'pengaduan';
    final url = Uri.parse('$baseUrl/respons/$typeString');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_pengajuan': idPengajuan,
          'pesan': pesan,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final respons = ResponsAdmin.fromJson(body['data'] ?? body);

        _respons.insert(0, respons);
        notifyListeners();

        // Notifikasi dari server akan di-fetch ulang otomatis
        // saat warga membuka beranda atau halaman notifikasi

        return true;
      } else {
        debugPrint('ERROR kirimRespons: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('ERROR kirimRespons: $e');
      return false;
    }
  }

  // ── Ambil Respons untuk ID tertentu ────────────────────

  ResponsAdmin? getResponsById(String id) {
    try {
      return _respons.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ResponsAdmin> getResponsByPengajuanId(String idPengajuan) {
    return _respons.where((r) => r.idPengajuan == idPengajuan).toList();
  }

  // ── Cache Management (SharedPreferences) ────────────────

  Future<void> _cacheSimpanRespons(
    String idPengajuan,
    List<ResponsAdmin> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'respons_cache_$idPengajuan';
      final jsonString = jsonEncode(
        items.map((r) => r.toJson()).toList(),
      );
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('ERROR _cacheSimpanRespons: $e');
    }
  }

  Future<List<ResponsAdmin>> _cacheAmbilRespons(String idPengajuan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'respons_cache_$idPengajuan';
      final jsonString = prefs.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonData = jsonDecode(jsonString) as List;
        return jsonData
            .map((item) => ResponsAdmin.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR _cacheAmbilRespons: $e');
      return [];
    }
  }

  Future<void> clearCache(String idPengajuan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'respons_cache_$idPengajuan';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('ERROR clearCache: $e');
    }
  }

  // ── Clear All ──────────────────────────────────────────

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('respons_cache_')) {
          await prefs.remove(key);
        }
      }
      _respons.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR clearAll: $e');
    }
  }
}
