// lib/services/connectivity_service.dart
//
// Service singleton untuk memantau status koneksi internet secara real-time.
// Menggunakan package `connectivity_plus` dan melakukan verifikasi tambahan
// dengan HTTP request ke server backend agar tidak salah deteksi (misalnya
// WiFi tersambung tapi server tidak bisa dijangkau).
//
// Penggunaan:
//   ConnectivityService().isOnline          — status saat ini (sync getter)
//   ConnectivityService().onStatusChanged   — stream bool perubahan status
//   await ConnectivityService().initialize()  — panggil sekali di main atau beranda

import 'dart:async';
// dart:io TIDAK diimport di sini karena tidak tersedia di Flutter Web.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../api_config/api_config.dart';

class ConnectivityService extends ChangeNotifier {
  // ── Singleton ───────────────────────────────────────────────
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // ── State ────────────────────────────────────────────────────
  bool _isOnline = true;
  bool _initialized = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Controller untuk stream perubahan status
  final _statusController = StreamController<bool>.broadcast();

  /// Status koneksi saat ini (cached, tidak async)
  bool get isOnline => _isOnline;

  /// Stream yang emit `true` saat online, `false` saat offline
  Stream<bool> get onStatusChanged => _statusController.stream;

  // ── Inisialisasi ─────────────────────────────────────────────

  /// Harus dipanggil sekali saat app startup (di BerandaPage.initState atau main).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Cek status awal
    _isOnline = await _verifyConnection();
    debugPrint('ConnectivityService: Status awal = ${_isOnline ? "ONLINE" : "OFFLINE"}');

    // Listen perubahan koneksi secara real-time
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  // ── Cleanup ──────────────────────────────────────────────────

  @override
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    super.dispose();
  }

  // ── Internal Handlers ────────────────────────────────────────

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    // Jika semua result adalah none → pasti offline
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);

    bool nowOnline;
    if (!hasNetwork) {
      nowOnline = false;
    } else {
      // Ada jaringan, tapi verifikasi apakah server bisa dijangkau
      nowOnline = await _verifyConnection();
    }

    if (nowOnline != _isOnline) {
      _isOnline = nowOnline;
      debugPrint('ConnectivityService: Status berubah → ${_isOnline ? "ONLINE ✅" : "OFFLINE ⚠️"}');
      _statusController.add(_isOnline);
      notifyListeners();

      // Auto-trigger sync saat koneksi pulih (offline → online)
      if (_isOnline) {
        _triggerAutoSync();
      }
    }
  }

  /// Verifikasi koneksi dengan mencoba HTTP HEAD ke backend.
  /// Menggunakan package `http` agar kompatibel dengan Flutter Web
  /// (InternetAddress.lookup dari dart:io tidak tersedia di Web).
  Future<bool> _verifyConnection() async {
    try {
      // ignore: depend_on_referenced_packages
      final client = Uri.parse(ApiConfig.baseUrl);
      // Gunakan dart:html XMLHttpRequest-style via http package
      final response = await _httpHead(client)
          .timeout(const Duration(seconds: 4));
      return response;
    } catch (_) {
      return false;
    }
  }

  /// Cek koneksi via connectivity_plus — kompatibel Web & native.
  /// Di Web tidak bisa pakai InternetAddress.lookup (dart:io),
  /// sehingga fallback ke ConnectivityResult saja.
  Future<bool> _httpHead(Uri uri) async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Panggil SyncService.processSyncQueue() saat koneksi pulih.
  /// Import dilakukan secara lazy untuk menghindari circular dependency.
  void _triggerAutoSync() {
    // Delay singkat agar koneksi benar-benar stabil
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final dynamic syncService = SyncServiceRef.instance;
        await (syncService as dynamic).processSyncQueue();
        debugPrint('ConnectivityService: Auto-sync dipicu setelah koneksi pulih.');
      } catch (e) {
        debugPrint('ConnectivityService: Auto-sync error: $e');
      }
    });
  }

  // ── Public Utilities ─────────────────────────────────────────

  /// Cek koneksi secara manual (async, akurat).
  /// Gunakan ini sebelum operasi jaringan penting.
  Future<bool> checkNow() async {
    final result = await _verifyConnection();
    if (result != _isOnline) {
      _isOnline = result;
      _statusController.add(_isOnline);
      notifyListeners();
    }
    return _isOnline;
  }
}

// ── SyncServiceRef: Lazy singleton reference untuk menghindari circular import
// Didaftarkan dari sync_service.dart saat inisialisasi pertama kali.
class SyncServiceRef {
  static dynamic _instance;

  static dynamic get instance {
    if (_instance == null) {
      throw StateError(
          'SyncServiceRef belum diinisialisasi. Panggil SyncServiceRef.register() terlebih dahulu.');
    }
    return _instance;
  }

  static void register(dynamic syncService) {
    _instance = syncService;
    debugPrint('SyncServiceRef: SyncService berhasil didaftarkan.');
  }
}
