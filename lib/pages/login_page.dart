// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/fcm_service.dart';
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
    final hasToken = prefs.getString('auth_token') != null;

    if (isLogin && hasToken && mounted) {
      // Restore auth state, lalu init FCM
      await AuthService().checkLoginStatus();
      try {
        final fcm = FcmService();
        await fcm.initialize();
        await fcm.registerToken();
      } catch (e) {
        debugPrint("FCM initialization failed during checkLoginStatus: $e");
      }

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
      _nikCtrl.text.replaceAll(' ', '').trim(),
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
      await prefs.setString('nik', _nikCtrl.text.replaceAll(' ', '').trim());

      // Inisialisasi FCM dan daftarkan token ke server
      try {
        final fcm = FcmService();
        await fcm.initialize();
        await fcm.registerToken();
      } catch (e) {
        debugPrint("FCM initialization failed during login: $e");
      }

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
      backgroundColor: const Color(0xFF113EAD), // Royal Blue Background from image
      body: Stack(
        children: [
          // Background Decorative Circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTopSection(),
                        _buildFormCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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

          const SizedBox(height: 16),

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
            'Masuk ke akun anda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =====================================
  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Masukkan NIK dan Password Anda',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Nomor Kartu Keluarga',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _nikCtrl,
              keyboardType: TextInputType.number,
              maxLength: 19,
              inputFormatters: [
                ChunkedInputFormatter(),
              ],
              decoration: _inputDecoration(
                hint: '123xxxxxxxxxxxxxx',
                icon: Icons.person_outline,
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Nomor KK wajib diisi';
                }
                final clean = v.replaceAll(' ', '');
                if (clean.length != 16) {
                  return 'Nomor KK harus 16 digit';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _passCtrl,
              obscureText: !_showPass,
              decoration: _inputDecoration(
                hint: 'Masukkan Password',
                icon: Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showPass = !_showPass;
                    });
                  },
                  icon: Icon(
                    _showPass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
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

            const SizedBox(height: 32),

            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  height: 48,
                  width: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xFF133EAD),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
    String counterText = '',
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      counterText: counterText,
      prefixIcon: Icon(icon, color: Colors.black54),
      filled: true,
      fillColor: const Color(0xFFE8EEF9),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF113EAD), width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class ChunkedInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }
    
    final clean = text.replaceAll(RegExp(r'\D'), '');
    final digits = clean.length > 16 ? clean.substring(0, 16) : clean;
    
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    
    final formatted = buffer.toString();
    
    int offset = newValue.selection.end;
    int cleanCharsBeforeCursor = text.substring(0, offset).replaceAll(RegExp(r'\D'), '').length;
    
    int formattedOffset = 0;
    int digitCount = 0;
    while (formattedOffset < formatted.length && digitCount < cleanCharsBeforeCursor) {
      if (formatted[formattedOffset] != ' ') {
        digitCount++;
      }
      formattedOffset++;
    }
    
    if (formattedOffset < formatted.length && formatted[formattedOffset] == ' ') {
      formattedOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedOffset),
    );
  }
}