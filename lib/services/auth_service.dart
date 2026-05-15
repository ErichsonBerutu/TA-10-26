import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config/api_config.dart';
import '../models/user_model.dart';

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

  Future<bool> login(String nik, String password) async {
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
        final data = jsonDecode(response.body);

        final user = data["user"];
        _token = data["token"];

        _currentUser = User(
          id: user["id"],
          nik: user["nik"] ?? "",
          nama: user["name"] ?? "",
          email: user["email"] ?? "",
          role: user["role"] ?? "user",
          alamat: user["alamat"] ?? "",
          tempatLahir: user["tempat_lahir"] ?? "",
          tanggalLahir: DateTime.tryParse(
                user["tanggal_lahir"] ?? "",
              ) ??
              DateTime.now(),
        );

        _isLoggedIn = true;

        // Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("LOGIN ERROR : $e");
      return false;
    }
  }

// ==================================================
  // LOGOUT
  // ==================================================

  Future<void> logout() async {
    try {
      final url = Uri.parse("$baseUrl/logout");

      await http.post(
        url,
        headers: {
          "Authorization": "Bearer $_token",
          "Accept": "application/json",
        },
      );
    } catch (_) {}

    _currentUser = null;
    _token = null;
    _isLoggedIn = false;

    // Hapus dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    notifyListeners();
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