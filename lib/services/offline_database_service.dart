// lib/services/offline_database_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineDatabaseService {
  static final OfflineDatabaseService _instance = OfflineDatabaseService._internal();
  factory OfflineDatabaseService() => _instance;
  OfflineDatabaseService._internal();

  // Keys untuk SharedPreferences
  static const String _keyBerita = 'cache_berita';
  static const String _keyPengumuman = 'cache_pengumuman';
  static const String _keyPengaduan = 'cache_pengaduan';
  static const String _keyPengajuan = 'cache_pengajuan';
  static const String _keyNotifikasi = 'cache_notifikasi';
  static const String _keyJenisSurat = 'cache_jenis_surat';
  static const String _keySyncQueue = 'sync_queue';

  // ============================================================
  //  METODE SECARA UMUM (GENERIC SETTERS AND GETTERS)
  // ============================================================

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService._saveString ($key): $e');
    }
  }

  Future<String?> _getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService._getString ($key): $e');
      return null;
    }
  }

  // ============================================================
  //  CACHE BERITA
  // ============================================================

  Future<void> simpanBerita(List<Map<String, dynamic>> beritaList) async {
    final jsonString = jsonEncode(beritaList);
    await _saveString(_keyBerita, jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilBerita() async {
    final jsonString = await _getString(_keyBerita);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilBerita: $e');
      return [];
    }
  }

  // ============================================================
  //  CACHE PENGUMUMAN
  // ============================================================

  Future<void> simpanPengumuman(List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await _saveString(_keyPengumuman, jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilPengumuman() async {
    final jsonString = await _getString(_keyPengumuman);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilPengumuman: $e');
      return [];
    }
  }

  // ============================================================
  //  CACHE PENGADUAN
  // ============================================================

  Future<void> simpanPengaduan(List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await _saveString(_keyPengaduan, jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilPengaduan() async {
    final jsonString = await _getString(_keyPengaduan);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilPengaduan: $e');
      return [];
    }
  }

  // ============================================================
  //  CACHE PENGAJUAN SURAT
  // ============================================================

  Future<void> simpanPengajuan(List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await _saveString(_keyPengajuan, jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilPengajuan() async {
    final jsonString = await _getString(_keyPengajuan);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilPengajuan: $e');
      return [];
    }
  }

  // ============================================================
  //  CACHE NOTIFIKASI
  // ============================================================

  Future<void> simpanNotifikasi(List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await _saveString(_keyNotifikasi, jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilNotifikasi() async {
    final jsonString = await _getString(_keyNotifikasi);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilNotifikasi: $e');
      return [];
    }
  }

  // ============================================================
  //  CACHE JENIS SURAT
  // ============================================================

  Future<void> simpanJenisSurat(List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await _saveString(_keyJenisSurat, jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilJenisSurat() async {
    final jsonString = await _getString(_keyJenisSurat);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilJenisSurat: $e');
      return [];
    }
  }

  // ============================================================
  //  CACHE PERSYARATAN SURAT
  // ============================================================

  Future<void> simpanPersyaratan(int jenisSuratId, List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await _saveString('cache_persyaratan_$jenisSuratId', jsonString);
  }

  Future<List<Map<String, dynamic>>> ambilPersyaratan(int jenisSuratId) async {
    final jsonString = await _getString('cache_persyaratan_$jenisSuratId');
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilPersyaratan: $e');
      return [];
    }
  }

  // ============================================================
  //  OFFLINE SYNC QUEUE MANAGEMENT
  // ============================================================

  Future<List<Map<String, dynamic>>> ambilSyncQueue() async {
    final jsonString = await _getString(_keySyncQueue);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.ambilSyncQueue: $e');
      return [];
    }
  }

  Future<void> _simpanSyncQueue(List<Map<String, dynamic>> queue) async {
    final jsonString = jsonEncode(queue);
    await _saveString(_keySyncQueue, jsonString);
  }

  Future<void> tambahKeSyncQueue({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final queue = await ambilSyncQueue();
    queue.add({
      'id': 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
      'action': action,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _simpanSyncQueue(queue);
    debugPrint('OfflineDatabaseService: Item berhasil ditambahkan ke antrean sync ($action).');
  }

  Future<void> hapusDariSyncQueue(String id) async {
    final queue = await ambilSyncQueue();
    queue.removeWhere((item) => item['id'] == id);
    await _simpanSyncQueue(queue);
    debugPrint('OfflineDatabaseService: Item dengan ID $id dihapus dari antrean sync.');
  }

  Future<void> bersihkanSemuaCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBerita);
      await prefs.remove(_keyPengumuman);
      await prefs.remove(_keyPengaduan);
      await prefs.remove(_keyPengajuan);
      await prefs.remove(_keyNotifikasi);
      await prefs.remove(_keyJenisSurat);
      // Catatan: sync_queue jangan dibersihkan agar antrean offline yang belum sinkron tidak hilang
    } catch (e) {
      debugPrint('ERROR OfflineDatabaseService.bersihkanSemuaCache: $e');
    }
  }
}
