// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
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

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _checkLoginStatus();

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

  // =====================================
  // AUTO LOGIN (SEPERTI FB / IG)
  // =====================================
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final isLogin = prefs.getBool('is_login') ?? false;

    if (isLogin && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BerandaPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nikCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // =====================================
  // LOGIN API
  // =====================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final authService = AuthService();
    final result = await authService.login(
      _nikCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;

    final isConnectionError = result.message.contains('Koneksi terputus');
    final snackColor = result.success
        ? Colors.green
        : isConnectionError
            ? Colors.orange
            : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: snackColor,
      ),
    );

    if (result.success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_login', true);
      await prefs.setString('nik', _nikCtrl.text.trim());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BerandaPage(),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // =====================================
  // UI
  // =====================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      _buildTopSection(),
                      _buildFormCard(),
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

  // =====================================
  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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

          const SizedBox(height: 18),

          const Text(
            'Hutabulu Mejan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Masuk ke akun Anda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =====================================
  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selamat Datang 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Masukkan NIK dan Password',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 25),

            TextFormField(
              controller: _nikCtrl,
              keyboardType: TextInputType.number,
              maxLength: 16,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: _inputDecoration(
                hint: 'Masukkan NIK',
                icon: Icons.badge,
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'NIK wajib diisi';
                }
                if (v.length != 16) {
                  return 'NIK harus 16 digit';
                }
                return null;
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: _passCtrl,
              obscureText: !_showPass,
              decoration: _inputDecoration(
                hint: 'Masukkan Password',
                icon: Icons.lock,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showPass = !_showPass;
                    });
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
                return null;
              },
            ),

            const SizedBox(height: 25),

            GestureDetector(
              onTap: _isLoading ? null : _login,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
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
          ],
        ),
      ),
    );
  }

  // =====================================
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}