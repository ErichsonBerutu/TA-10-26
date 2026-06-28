// Native platform helper: Android, iOS, Desktop
// File ini dipakai saat dart.library.io tersedia (bukan Web)

import 'dart:io';

// IP WiFi laptop saat ini — UPDATE ini jika pindah jaringan WiFi
// Jalankan 'ipconfig' di terminal untuk mendapatkan IPv4 Address terbaru
const String _laptopIp = '172.27.81.72';

String get nativeBaseUrl {
  if (Platform.isAndroid) {
    // Emulator Android menggunakan IP khusus 10.0.2.2 untuk akses localhost laptop
    // HP fisik Android menggunakan IP WiFi laptop langsung
    // Cara deteksi: coba baca file /proc/net/arp untuk cek apakah kita di emulator
    // Metode paling andal: cek apakah berjalan di emulator via environment
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
    // HP fisik — gunakan IP WiFi laptop
    return 'http://10.51.70.25:8000/api';
  } else if (Platform.isIOS) {
    // Simulator iOS bisa langsung pakai localhost
    return 'http://localhost:8000/api';
  } else {
    // Desktop (Windows/Linux/macOS)
    return 'http://localhost:8000/api';
  }
}
