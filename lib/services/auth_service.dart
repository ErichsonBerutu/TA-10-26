import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config/api_config.dart';
import '../models/user_model.dart';
import './fcm_service.dart';

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

      // Sinkronisasi data profil terbaru dari server secara asinkron
      fetchLatestProfile();
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
      ).timeout(const Duration(seconds: 10));

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
            jenisKelamin: user["jenis_kelamin"] ?? user["kelamin"] ?? user["gender"] ?? "",
            noKtp: user["no_ktp"] ?? user["nomor_ktp"] ?? user["ktp"] ?? user["nik"] ?? "",
            suku: user["suku"] ?? user["etnis"] ?? "",
            namaAyah: user["nama_ayah"] ?? user["ayah"] ?? "",
            namaIbu: user["nama_ibu"] ?? user["ibu"] ?? "",
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
        return LoginResult(false, responseData['message'] ?? 'Nomor KK / Password salah');
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

    // Hapus FCM token sebelum logout (stop push notification)
    try {
      await FcmService().removeToken();
    } catch (_) {}

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
      ).timeout(const Duration(seconds: 10));

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

  // ==================================================
  // FETCH LATEST PROFILE (SYNC FROM SERVER)
  // ==================================================

  Future<void> fetchLatestProfile() async {
    if (_token == null) return;
    try {
      final url = Uri.parse("$baseUrl/me");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $_token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final userMap = responseData["data"]["user"];
          if (userMap != null) {
            _currentUser = User(
              id: userMap["id"],
              nik: userMap["nik"] ?? "",
              noKk: userMap["no_kk"] ?? userMap["kk"] ?? userMap["no_kartu_keluarga"] ?? "",
              nama: userMap["name"] ?? userMap["nama"] ?? "",
              email: userMap["email"] ?? "",
              role: userMap["role"] ?? "masyarakat",
              alamat: userMap["alamat"] ?? "",
              tempatLahir: userMap["tempat_lahir"] ?? "",
              tanggalLahir: DateTime.tryParse(userMap["tanggal_lahir"] ?? "") ?? DateTime.now(),
              agama: userMap["agama"] ?? "",
              jenisKelamin: userMap["jenis_kelamin"] ?? userMap["kelamin"] ?? userMap["gender"] ?? "",
              noKtp: userMap["no_ktp"] ?? userMap["nomor_ktp"] ?? userMap["ktp"] ?? userMap["nik"] ?? "",
              suku: userMap["suku"] ?? userMap["etnis"] ?? "",
              namaAyah: userMap["nama_ayah"] ?? userMap["ayah"] ?? "",
              namaIbu: userMap["nama_ibu"] ?? userMap["ibu"] ?? "",
            );

            // Simpan ke SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
            notifyListeners();
            debugPrint("PROFILE SYNCED SUCCESSFULLY: jenisKelamin = ${_currentUser!.jenisKelamin}");
          }
        }
      }
    } catch (e) {
      debugPrint("FETCH PROFILE ERROR : $e");
    }
  }

}