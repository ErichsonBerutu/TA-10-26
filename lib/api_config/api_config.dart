import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Menggunakan localhost karena port 8000 telah di-reverse via ADB (adb reverse tcp:8000 tcp:8000)
      // Ini menjamin koneksi lancar tanpa terhalang Windows Defender Firewall atau isolasi Wi-Fi.
      return "http://172.27.69.109:8000/api";
    } else if (Platform.isIOS) {
      // Simulator iOS di laptop bisa langsung membaca localhost
      return "http://localhost:8000/api";
    } else {
      // Untuk platform lain seperti Chrome/Web atau Desktop
      return "http://localhost:8000/api";
    }
  }
}
