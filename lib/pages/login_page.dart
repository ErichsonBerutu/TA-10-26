// lib/pages/login_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'register_page.dart';
import 'beranda_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nikCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _showPass = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ===============================
  // GANTI IP SESUAI LAPTOP KAMU
  // Emulator Android = 10.0.2.2
  // HP Asli WiFi sama = IP Laptop
  // ===============================
  final String baseUrl = 'http://172.27.69.178:8000/api';

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nikCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ======================================================
  // LOGIN API
  // ======================================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'nik': _nikCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const BerandaPage(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: anim,
                child: child,
              );
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ======================================================
  // BUILD
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0f2460),
                    Color(0xFF1e40af),
                    Color(0xFF2563eb),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: _bgCircle(180, 0.07),
                  ),
                  Positioned(
                    top: 80,
                    left: -30,
                    child: _bgCircle(100, 0.05),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      _buildTopSection(),
                      _buildFormCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // HEADER
  // ======================================================
  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Text(
                      '🏡',
                      style: TextStyle(fontSize: 40),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Hutabulu Mejan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Masuk ke akun Anda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ======================================================
  // FORM CARD
  // ======================================================
  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1e40af).withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Masukkan NIK dan password Anda',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94a3b8),
              ),
            ),

            const SizedBox(height: 24),

            _fieldLabel('Nomor Induk Kependudukan (NIK)'),
            const SizedBox(height: 8),

            TextFormField(
              controller: _nikCtrl,
              keyboardType: TextInputType.number,
              maxLength: 16,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: _inputDecoration(
                hint: '3212XXXXXXXXXXXX',
                icon: Icons.badge_rounded,
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'NIK wajib diisi';
                }
                if (v.length != 16) {
                  return 'NIK harus 16 digit';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _fieldLabel('Password'),
            const SizedBox(height: 8),

            TextFormField(
              controller: _passCtrl,
              obscureText: !_showPass,
              decoration: _inputDecoration(
                hint: 'Masukkan password',
                icon: Icons.lock_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _showPass = !_showPass);
                  },
                  icon: Icon(
                    _showPass
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Password wajib diisi';
                }
                if (v.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) {
                    setState(() => _rememberMe = v ?? false);
                  },
                ),
                const Text('Ingat saya'),
              ],
            ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: _isLoading ? null : _login,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1e40af),
                      Color(0xFF2563eb),
                    ],
                  ),
                ),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                );
              },
              child: const Center(
                child: Text(
                  'Belum punya akun? Daftar',
                  style: TextStyle(
                    color: Color(0xFF2563eb),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String counterText = ' ',
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: counterText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _bgCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}