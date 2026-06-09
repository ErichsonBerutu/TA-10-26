import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Menggunakan IP lokal laptop yang aktif saat ini agar HP Android fisik dapat terhubung
      return "http://172.19.82.25:8000/api";
    } else if (Platform.isIOS) {
      // Simulator iOS di laptop bisa langsung membaca localhost
      return "http://localhost:8000/api";
    } else {
      // Untuk platform lain seperti Chrome/Web atau Desktop
      return "http://localhost:8000/api";
    }
  }
}