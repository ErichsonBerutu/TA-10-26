import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://192.168.1.8:8000/api";
    } else {
      return "http://localhost:8000/api";
    }
  }
}