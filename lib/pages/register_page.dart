// lib/pages/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _konfPassCtrl = TextEditingController();

  bool _showPass = false;
  bool _showKonfPass = false;
  bool _isLoading = false;
  bool _setuju = false;

  String? _jenisKelamin;
  DateTime? _tanggalLahir;

  // Step wizard: 0 = data diri, 1 = akun
  int _step = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _namaCtrl.dispose();
    _nikCtrl.dispose();
    _noHpCtrl.dispose();
    _alamatCtrl.dispose();
    _passCtrl.dispose();
    _konfPassCtrl.dispose();
    super.dispose();
  }

  // ── Pilih tanggal lahir ────────────────────────────────────

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 17),
      helpText: 'Pilih Tanggal Lahir',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2563eb),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  String _formatTgl(DateTime dt) {
    const b = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${b[dt.month - 1]} ${dt.year}';
  }

  // ── Validasi step 0 ────────────────────────────────────────

  bool _validateStep0() {
    bool valid = true;

    if (_namaCtrl.text.trim().isEmpty || _namaCtrl.text.trim().length < 3) {
      valid = false;
    }
    if (_nikCtrl.text.length != 16) valid = false;
    if (_noHpCtrl.text.trim().length < 10) valid = false;
    if (_alamatCtrl.text.trim().isEmpty) valid = false;
    if (_tanggalLahir == null) valid = false;
    if (_jenisKelamin == null) valid = false;

    if (!valid) {
      _formKey.currentState!.validate();
      if (_tanggalLahir == null) {
        _showSnack('Tanggal lahir wajib dipilih', isError: true);
      }
      if (_jenisKelamin == null) {
        _showSnack('Jenis kelamin wajib dipilih', isError: true);
      }
    }
    return valid;
  }

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _daftar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_setuju) {
      _showSnack('Anda harus menyetujui syarat & ketentuan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // TODO: ganti dengan panggil API Golang POST /api/v1/auth/register
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSuccessDialog();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFdc2626)
            : const Color(0xFF16a34a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ade80), Color(0xFF16a34a)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16a34a).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pendaftaran Berhasil!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Akun Anda telah berhasil dibuat. Silakan masuk menggunakan NIK dan password yang telah didaftarkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // tutup dialog
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (_, __, ___) => const LoginPage(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563eb).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Masuk Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          // Background atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
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
                  Positioned(top: -40, right: -40, child: _bgCircle(150, 0.07)),
                  Positioned(top: 60, left: -20, child: _bgCircle(80, 0.05)),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daftar Akun',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Isi data diri dengan benar',
                              style: TextStyle(
                                color: Color(0x99ffffff),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Step indicator ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStepIndicator(),
                ),
                const SizedBox(height: 16),

                // ── Form ─────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Form(
                          key: _formKey,
                          child: _step == 0 ? _buildStep0() : _buildStep1(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ─────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(0, 'Data Diri'),
        Expanded(
          child: Container(
            height: 2,
            color: _step >= 1
                ? const Color(0xFF2563eb)
                : const Color(0xFFe2e8f0),
          ),
        ),
        _stepDot(1, 'Akun'),
      ],
    );
  }

  Widget _stepDot(int step, String label) {
    final active = _step == step;
    final done = _step > step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (active || done) ? const Color(0xFF2563eb) : Colors.white,
            border: Border.all(
              color: (active || done)
                  ? const Color(0xFF2563eb)
                  : const Color(0xFFe2e8f0),
              width: 2,
            ),
            boxShadow: (active || done)
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563eb).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : const Color(0xFF94a3b8),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: (active || done)
                ? const Color(0xFF2563eb)
                : const Color(0xFF94a3b8),
          ),
        ),
      ],
    );
  }

  // ── Step 0: Data Diri ──────────────────────────────────────

  Widget _buildStep0() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1e40af).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('', 'Silahkan Isi Data Diri Anda'),
          const SizedBox(height: 20),

          // Nama lengkap
          _fieldLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _namaCtrl,
            hint: 'Sesuai KTP',
            icon: Icons.person_rounded,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
              if (v.trim().length < 3) return 'Nama minimal 3 karakter';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // NIK
          _fieldLabel('NIK'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nikCtrl,
            hint: '16 digit NIK',
            icon: Icons.badge_rounded,
            keyboardType: TextInputType.number,
            maxLength: 16,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            letterSpacing: 1.5,
            validator: (v) {
              if (v == null || v.isEmpty) return 'NIK wajib diisi';
              if (v.length != 16) return 'NIK harus 16 digit';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // No HP
          _fieldLabel('Nomor HP'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _noHpCtrl,
            hint: '08XXXXXXXXXX',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'No HP wajib diisi';
              if (v.length < 10) return 'No HP tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Jenis Kelamin
          _fieldLabel('Jenis Kelamin'),
          const SizedBox(height: 8),
          Row(
            children: [
              _jenisKelaminBtn('Laki-laki', '👨'),
              const SizedBox(width: 10),
              _jenisKelaminBtn('Perempuan', '👩'),
            ],
          ),
          const SizedBox(height: 14),

          // Tanggal Lahir
          _fieldLabel('Tanggal Lahir'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pilihTanggal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFe2e8f0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFeff6ff),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF2563eb),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tanggalLahir != null
                          ? _formatTgl(_tanggalLahir!)
                          : 'Pilih tanggal lahir',
                      style: TextStyle(
                        fontSize: 13,
                        color: _tanggalLahir != null
                            ? const Color(0xFF0f172a)
                            : const Color(0xFFcbd5e1),
                        fontWeight: _tanggalLahir != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94a3b8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Alamat
          _fieldLabel('Alamat Lengkap'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _alamatCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0f172a)),
            decoration: InputDecoration(
              hintText: 'Jl. / Dusun / RT RW / Desa ...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFFcbd5e1),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff6ff),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF2563eb),
                    size: 18,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 54),
              filled: true,
              fillColor: const Color(0xFFf8fafc),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563eb),
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFef4444)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFef4444),
                  width: 1.8,
                ),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
          ),
          const SizedBox(height: 24),

          // Tombol Lanjut
          GestureDetector(
            onTap: () {
              if (_validateStep0()) {
                setState(() => _step = 1);
                _animCtrl.reset();
                _animCtrl.forward();
              }
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563eb).withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lanjut',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jenisKelaminBtn(String value, String emoji) {
    final selected = _jenisKelamin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jenisKelamin = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563eb) : const Color(0xFFf8fafc),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563eb)
                  : const Color(0xFFe2e8f0),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563eb).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Akun ───────────────────────────────────────────

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1e40af).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔐', 'Buat Password'),
          const SizedBox(height: 6),
          const Text(
            'Password digunakan bersama NIK untuk login',
            style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
          ),
          const SizedBox(height: 20),

          // Ringkasan data diri
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFeff6ff),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFbfdbfe)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563eb).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF2563eb),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _namaCtrl.text.isEmpty ? '-' : _namaCtrl.text,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0f172a),
                        ),
                      ),
                      Text(
                        'NIK: ${_nikCtrl.text}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748b),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _step = 0);
                    _animCtrl.reset();
                    _animCtrl.forward();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563eb).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563eb),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Password
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: !_showPass,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
            decoration: _passDecoration(
              'Buat password (min. 8 karakter)',
              Icons.lock_rounded,
              _showPass,
              () => setState(() => _showPass = !_showPass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 8) return 'Password minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Indikator kekuatan password
          if (_passCtrl.text.isNotEmpty) _buildPasswordStrength(_passCtrl.text),
          const SizedBox(height: 14),

          // Konfirmasi Password
          _fieldLabel('Konfirmasi Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _konfPassCtrl,
            obscureText: !_showKonfPass,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0f172a)),
            decoration: _passDecoration(
              'Ulangi password',
              Icons.lock_outline_rounded,
              _showKonfPass,
              () => setState(() => _showKonfPass = !_showKonfPass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Konfirmasi password wajib diisi';
              if (v != _passCtrl.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Syarat & ketentuan
          GestureDetector(
            onTap: () => setState(() => _setuju = !_setuju),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: _setuju ? const Color(0xFF2563eb) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _setuju
                          ? const Color(0xFF2563eb)
                          : const Color(0xFFcbd5e1),
                      width: 1.5,
                    ),
                  ),
                  child: _setuju
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Saya menyetujui ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748b),
                          ),
                        ),
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563eb),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' penggunaan aplikasi Desa Hutabulu Mejan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Daftar
          GestureDetector(
            onTap: _isLoading ? null : _daftar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [const Color(0xFF94a3b8), const Color(0xFF64748b)]
                      : [const Color(0xFF16a34a), const Color(0xFF15803d)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isLoading
                                ? const Color(0xFF94a3b8)
                                : const Color(0xFF16a34a))
                            .withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.how_to_reg_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Daftarkan Akun',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sudah punya akun
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Sudah punya akun? ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748b)),
                    ),
                    TextSpan(
                      text: 'Masuk di sini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2563eb),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Password strength indicator ────────────────────────────

  Widget _buildPasswordStrength(String pass) {
    int strength = 0;
    if (pass.length >= 8) strength++;
    if (pass.contains(RegExp(r'[A-Z]'))) strength++;
    if (pass.contains(RegExp(r'[0-9]'))) strength++;
    if (pass.contains(RegExp(r'[!@#\$%^&*]'))) strength++;

    final labels = ['Sangat Lemah', 'Lemah', 'Cukup', 'Kuat'];
    final colors = [
      const Color(0xFFdc2626),
      const Color(0xFFf97316),
      const Color(0xFFd97706),
      const Color(0xFF16a34a),
    ];
    final idx = (strength - 1).clamp(0, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength ? colors[idx] : const Color(0xFFe2e8f0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strength > 0 ? 'Password: ${labels[idx]}' : '',
          style: TextStyle(
            fontSize: 11,
            color: strength > 0 ? colors[idx] : Colors.transparent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Helper ─────────────────────────────────────────────────

  Widget _sectionTitle(String emoji, String title) {
    return Row(
      children: [
        if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 20)),
        if (emoji.isNotEmpty) const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0f172a),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    double letterSpacing = 0,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 13,
        color: const Color(0xFF0f172a),
        letterSpacing: letterSpacing,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFcbd5e1),
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        counterText: '',
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFeff6ff),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF2563eb), size: 18),
        ),
        filled: true,
        fillColor: const Color(0xFFf8fafc),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563eb), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFef4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.8),
        ),
      ),
      validator: validator,
    );
  }

  InputDecoration _passDecoration(
    String hint,
    IconData icon,
    bool show,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFcbd5e1)),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFeff6ff),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: const Color(0xFF2563eb), size: 18),
      ),
      suffixIcon: GestureDetector(
        onTap: toggle,
        child: Icon(
          show ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: const Color(0xFF94a3b8),
          size: 20,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFf8fafc),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563eb), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFef4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.8),
      ),
    );
  }

  Widget _bgCircle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}
