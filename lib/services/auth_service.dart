import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config/api_config.dart';
import '../models/user_model.dart';

class LoginResult {
  final bool success;
  final String message;

  LoginResult(this.success, this.message);
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;
  AuthService._internal();

  static String get baseUrl => ApiConfig.baseUrl;

  User? _currentUser;
  bool _isLoggedIn = false;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  // ==================================================
  // CHECK LOGIN STATUS FROM STORAGE
  // ==================================================

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');

    if (token != null && userJson != null) {
      _token = token;
      _currentUser = User.fromJson(jsonDecode(userJson));
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<LoginResult> login(String nik, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login");

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nik": nik,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Pastikan status dari backend adalah 'success'
        if (responseData['status'] == 'success') {
          
          // MENGAMBIL DATA DENGAN JALUR JSON YANG BENAR
          final user = responseData["data"]["user"];
          _token = responseData["data"]["token"];

          _currentUser = User(
            id: user["id"],
            nik: user["nik"] ?? "",
            noKk: user["no_kk"] ?? user["kk"] ?? user["no_kartu_keluarga"] ?? "",
            nama: user["name"] ?? user["nama"] ?? "", // Menyesuaikan dengan 'name' dari Laravel
            email: user["email"] ?? "",
            role: user["role"] ?? "masyarakat",
            alamat: user["alamat"] ?? "",
            tempatLahir: user["tempat_lahir"] ?? "",
            tanggalLahir: DateTime.tryParse(
                  user["tanggal_lahir"] ?? "",
                ) ??
                DateTime.now(),
            agama: user["agama"] ?? "",
          );

          _isLoggedIn = true;

          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));

          notifyListeners();
          return LoginResult(true, 'Login berhasil');
        } else {
          // Menangkap jika statusnya 'error' (meskipun HTTP 200 OK)
          return LoginResult(false, responseData['message'] ?? 'Login gagal');
        }
      }

      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return LoginResult(false, responseData['message'] ?? 'NIK / Password salah');
      }

      if (response.statusCode == 403) {
        final responseData = jsonDecode(response.body);
        return LoginResult(false, responseData['message'] ?? 'Akses ditolak');
      }

      if (response.statusCode == 422) {
        return LoginResult(false, 'Data login tidak valid');
      }

      return LoginResult(false, 'Login gagal. Status ${response.statusCode}');
    } catch (e) {
      debugPrint("LOGIN ERROR : $e");
      return LoginResult(false, 'Koneksi terputus. Periksa internet atau server lokal Anda.');
    }
  }

  // ==================================================
  // LOGOUT
  // ==================================================

  Future<void> logout() async {
    final tokenToRevoke = _token;

    _currentUser = null;
    _token = null;
    _isLoggedIn = false;

    // Hapus dari SharedPreferences secara instan
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    await prefs.remove('is_login');

    notifyListeners();

    // Kirim request ke server asinkron di latar belakang menggunakan copy token
    if (tokenToRevoke != null) {
      try {
        final url = Uri.parse("$baseUrl/logout");
        http.post(
          url,
          headers: {
            "Authorization": "Bearer $tokenToRevoke",
            "Accept": "application/json",
          },
        );
      } catch (_) {}
    }
  }

  // ==================================================
  // UPDATE PROFILE
  // ==================================================

  Future<bool> updateProfile(User updatedUser) async {
    try {
      final url = Uri.parse("$baseUrl/profile/update");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $_token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama": updatedUser.nama,
          "alamat": updatedUser.alamat,
          "tempat_lahir": updatedUser.tempatLahir,
          "tanggal_lahir":
              updatedUser.tanggalLahir?.toIso8601String() ?? "",
          "no_kk": updatedUser.noKk,
        }),
      );

      if (response.statusCode == 200) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("UPDATE ERROR : $e");
      return false;
    }
  }

}