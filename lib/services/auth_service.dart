import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  User? _currentUser;
  bool _isLoggedIn = false;

  // Singleton pattern
  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    // Set default user untuk testing
    _initDefaultUser();
  }

  void _initDefaultUser() {
    _currentUser = User(
      nik: '1234567890123456',
      nama: 'Budi Santoso',
      email: 'budi@example.com',
      noHp: '081234567890',
      alamat: 'Jalan Merdeka No. 123, Desa Hutabulu Mejan',
      jenisKelamin: 'Laki-laki',
      tanggalLahir: DateTime(1990, 5, 15),
      loginAt: DateTime.now(),
    );
    _isLoggedIn = true;
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  /// Login user dengan NIK dan password
  /// Simulasi login, nantinya akan diganti API
  Future<bool> login(String nik, String password) async {
    try {
      // Simulasi delay network
      await Future.delayed(const Duration(milliseconds: 1500));

      // TODO: Ganti dengan API call ke Golang backend
      // Contoh respons dari API:
      _currentUser = User(
        nik: nik,
        nama: 'Budi Santoso', // dari API
        email: 'budi@example.com', // dari API
        noHp: '081234567890', // dari API
        alamat: 'Jalan Merdeka No. 123', // dari API
        jenisKelamin: 'Laki-laki',
        tanggalLahir: DateTime(1990, 5, 15),
        loginAt: DateTime.now(),
      );

      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout user
  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Update profil user
  Future<bool> updateProfile(User updatedUser) async {
    try {
      // TODO: API call ke backend
      await Future.delayed(const Duration(milliseconds: 1000));

      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
