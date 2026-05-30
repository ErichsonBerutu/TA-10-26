// lib/services/fcm_service.dart
//
// Firebase Cloud Messaging Service untuk Flutter.
// Mengelola inisialisasi Firebase, request izin notifikasi,
// pengiriman token ke backend, dan handling pesan masuk.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import './auth_service.dart';
import './notifikasi_service.dart';

// ============================================================
//  TOP-LEVEL FUNCTION: Background message handler
//  Harus top-level (bukan method di dalam class)
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background message: ${message.notification?.title}');
}

// ============================================================
//  FCM SERVICE
// ============================================================

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification Channel (Android) ─────────────────────────

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting',
    description: 'Channel untuk notifikasi penting dari Desa Hutabulu Mejan',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ── Inisialisasi ──────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Buat notification channel di Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. Inisialisasi local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('FCM: Tap notification, payload: ${details.payload}');
      },
    );

    // 3. Request izin notifikasi
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM: Izin notifikasi: ${settings.authorizationStatus}');

    // 4. Setup foreground message listener
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Setup notification tap handler (saat app di-background lalu di-tap)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Cek apakah app dibuka dari notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _initialized = true;
    debugPrint('FCM: Service berhasil diinisialisasi');
    
    // Ambil token secara otomatis saat inisialisasi agar selalu terpantau di log
    await registerToken();
  }

  // ── Ambil & Kirim Token ke Backend ────────────────────────

  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token Full: $token');
        await _sendTokenToServer(token);
      }

      // Listen token refresh (jika token berubah)
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      debugPrint('FCM: Error saat register token: $e');
    }
  }

  Future<void> _sendTokenToServer(String fcmToken) async {
    final authToken = AuthService().token;
    if (authToken == null) {
      debugPrint('FCM: Belum login, skip kirim token ke server');
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/fcm-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('FCM: Token berhasil dikirim ke server');
      } else {
        debugPrint('FCM: Gagal kirim token, status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('FCM: Error kirim token ke server: $e');
    }
  }

  // ── Foreground Message Handler ────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM Foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Tampilkan local notification banner
    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Notifikasi',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: message.data.toString(),
    );

    // Refresh daftar notifikasi di service agar UI langsung update
    NotifikasiService().loadNotifikasi(forceRefresh: true);
  }

  // ── Background/Terminated Tap Handler ─────────────────────

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM: App dibuka dari notification: ${message.notification?.title}');
    // Refresh notifikasi saat user tap
    NotifikasiService().loadNotifikasi(forceRefresh: true);
  }

  // ── Hapus Token (saat Logout) ─────────────────────────────

  Future<void> removeToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM: Token dihapus (logout)');
    } catch (e) {
      debugPrint('FCM: Error hapus token: $e');
    }
  }
}
