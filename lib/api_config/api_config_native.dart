// Native platform helper: Android, iOS, Desktop
// File ini dipakai saat dart.library.io tersedia (bukan Web)

import 'dart:io';
import 'package:flutter/foundation.dart';

// IP WiFi laptop saat ini — UPDATE ini jika pindah jaringan WiFi untuk testing lokal (Debug Mode)
// Jalankan 'ipconfig' di terminal untuk mendapatkan IPv4 Address terbaru
const String _laptopIp = '10.130.7.25';

String get nativeBaseUrl {
  // Jika aplikasi di-build untuk Release (seperti di GitHub Release),
  // gunakan server produksi/online hosting
  if (kReleaseMode) {
    return 'https://desahutabulumejan.id/api';
  }

  if (Platform.isAndroid) {
    // Emulator Android menggunakan IP khusus 10.0.2.2 untuk akses localhost laptop
    try {
      final result = File('/proc/net/arp').readAsStringSync();
      // Emulator AVD selalu punya gateway 10.0.2.2 di routing table
      if (result.contains('10.0.2.')) {
        // Ini emulator AVD — gunakan alamat khusus emulator
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {
      // Tidak bisa baca file (tidak apa-apa, lanjut ke fallback)
    }
    // HP fisik dalam Mode Debug — gunakan IP WiFi laptop yang aktif
    return 'http://$_laptopIp:8000/api';
  } else if (Platform.isIOS) {
    // Simulator iOS dalam Mode Debug bisa langsung pakai localhost
    return 'http://localhost:8000/api';
  } else {
    // Desktop (Windows/Linux/macOS)
    return 'http://localhost:8000/api';
  }
}
