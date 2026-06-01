// lib/services/alert_service.dart
//
// Layanan getaran & suara untuk notifikasi real-time.
// Dipanggil saat ada notifikasi baru masuk (polling maupun FCM foreground).

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  bool _notifInitialized = false;

  // Pola getaran: diam 0ms, getar 200ms, diam 100ms, getar 300ms
  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 200, 100, 300]);

  // ── Channel untuk in-app sound alert (terpisah dari FCM channel) ──
  static AndroidNotificationChannel get _alertChannel =>
      AndroidNotificationChannel(
        'notif_alert_channel',
        'Alert Notifikasi Baru',
        description: 'Bunyi & getar saat notifikasi baru masuk',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
      );

  // ── Inisialisasi channel & plugin ────────────────────────────────
  Future<void> init() async {
    if (_notifInitialized) return;

    // Daftarkan channel ke Android
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_alertChannel);

    // Inisialisasi plugin dengan ikon launcher
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings),
    );

    _notifInitialized = true;
    debugPrint('AlertService: channel & plugin initialized');
  }

  // ── Trigger getaran + bunyi saat notifikasi baru ─────────────────
  Future<void> triggerNewNotificationAlert({
    required String judul,
    required String pesan,
    String ikon = '🔔',
  }) async {
    await init();

    // 1. Getaran dengan pola: 200ms getar → 100ms diam → 300ms getar
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Pola getaran: [delay, getar, jeda, getar]
        await Vibration.vibrate(pattern: [0, 200, 100, 300]);
      } else {
        // Fallback: pakai HapticFeedback Flutter jika tidak ada vibrator
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('AlertService: getaran gagal: $e');
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    // 2. Tampilkan notifikasi banner dengan suara sistem default
    try {
      await _localNotif.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // ID unik
        '$ikon $judul',
        pesan,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _alertChannel.id,
            _alertChannel.name,
            channelDescription: _alertChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            vibrationPattern: _vibrationPattern,
            // Warna LED notifikasi: biru
            color: const Color(0xFF2563eb),
            enableLights: true,
            ledColor: const Color(0xFF2563eb),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );
    } catch (e) {
      debugPrint('AlertService: show notification gagal: $e');
    }
  }

  // ── Getaran ringan (untuk notifikasi FCM foreground) ──────────────
  Future<void> triggerLightVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 150);
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }
}
