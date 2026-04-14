// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_page.dart';
import 'beranda_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _nikCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _showPass      = false;
  bool _isLoading     = false;
  bool _rememberMe    = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nikCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Login ──────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // TODO: ganti dengan panggil API Golang
    // Simulasi delay network
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Simulasi berhasil → masuk beranda
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const BerandaPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: Stack(
        children: [
          // Background gradient atas
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0f2460), Color(0xFF1e40af), Color(0xFF2563eb)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(top: -50, right: -50, child: _bgCircle(180, 0.07)),
                Positioned(top: 80, left: -30, child: _bgCircle(100, 0.05)),
              ]),
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
                      // ── Header ──────────────────────────────
                      _buildTopSection(),

                      // ── Card Form ───────────────────────────
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

  // ── Top section (logo + judul) ─────────────────────────────

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(children: [
        // Logo
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Text('🏡', style: TextStyle(fontSize: 40))),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Hutabulu Mejan',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        Text(
          'Masuk ke akun Anda',
          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ── Form Card ──────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1e40af).withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Judul card
          const Text('Selamat Datang 👋', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0f172a))),
          const SizedBox(height: 4),
          const Text('Masukkan NIK dan password Anda', style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
          const SizedBox(height: 24),

          // ── Field NIK ──────────────────────────────────────
          _fieldLabel('Nomor Induk Kependudukan (NIK)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nikCtrl,
            keyboardType: TextInputType.number,
            maxLength: 16,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFF0f172a)),
            decoration: _inputDecoration(
              hint: '3212XXXXXXXXXXXX',
              icon: Icons.badge_rounded,
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
              if (v.length != 16) return 'NIK harus 16 digit';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Field Password ─────────────────────────────────
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: !_showPass,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
            decoration: _inputDecoration(
              hint: 'Masukkan password',
              icon: Icons.lock_rounded,
            ).copyWith(
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showPass = !_showPass),
                child: Icon(
                  _showPass ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: const Color(0xFF94a3b8), size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ── Remember me + Lupa password ───────────────────
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _rememberMe ? const Color(0xFF2563eb) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _rememberMe ? const Color(0xFF2563eb) : const Color(0xFFcbd5e1),
                      width: 1.5,
                    ),
                  ),
                  child: _rememberMe
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text('Ingat saya', style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {}, // TODO: lupa password
              child: const Text(
                'Lupa password?',
                style: TextStyle(fontSize: 12, color: Color(0xFF2563eb), fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 28),

          // ── Tombol Login ───────────────────────────────────
          GestureDetector(
            onTap: _isLoading ? null : _login,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [const Color(0xFF94a3b8), const Color(0xFF64748b)]
                      : [const Color(0xFF1e40af), const Color(0xFF2563eb)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_isLoading ? const Color(0xFF94a3b8) : const Color(0xFF2563eb)).withOpacity(0.4),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.login_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Divider ────────────────────────────────────────
          Row(children: [
            Expanded(child: Divider(color: const Color(0xFFe2e8f0), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ),
            Expanded(child: Divider(color: const Color(0xFFe2e8f0), thickness: 1)),
          ]),
          const SizedBox(height: 20),

          // ── Daftar akun ────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, __, ___) => const RegisterPage(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFeff6ff),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFbfdbfe), width: 1.5),
              ),
              child: const Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_add_rounded, color: Color(0xFF2563eb), size: 20),
                  SizedBox(width: 8),
                  Text('Buat Akun Baru', style: TextStyle(color: Color(0xFF2563eb), fontWeight: FontWeight.w800, fontSize: 15)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Footer ─────────────────────────────────────────
          Center(
            child: Text(
              '© 2025 Desa Hutabulu Mejan',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────────────

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)));
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, String counterText = ' '}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFcbd5e1)),
      counterText: counterText,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFeff6ff),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2563eb), size: 18),
      ),
      filled: true,
      fillColor: const Color(0xFFf8fafc),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border:             OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563eb), width: 1.8)),
      errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFef4444))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.8)),
    );
  }

  Widget _bgCircle(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
    );
  }
}