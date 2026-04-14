// lib/pages/pengaduan_page.dart
//
// ── SETUP ────────────────────────────────────────────────────
// pubspec.yaml:
//   dependencies:
//     file_picker: ^8.1.2
//     image_picker: ^1.1.2    ← tetap dipakai khusus untuk kamera
//
// Android — android/app/src/main/AndroidManifest.xml (dalam <manifest>):
//   <uses-permission android:name="android.permission.CAMERA"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
//
// iOS — ios/Runner/Info.plist:
//   <key>NSPhotoLibraryUsageDescription</key>
//   <string>Untuk melampirkan foto bukti pengaduan.</string>
//   <key>NSCameraUsageDescription</key>
//   <string>Untuk mengambil foto bukti pengaduan.</string>
// ────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pengaduan_model.dart';
import '../services/auth_service.dart';
import '../services/pengaduan_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'beranda_page.dart';
import 'pengumuman_page.dart';
import 'profile_page.dart';
import 'surat_page.dart';

// ============================================================
//  DATA JENIS PENGADUAN
// ============================================================

class _JenisData {
  final String label;
  final String emoji;
  final String desc;
  final JenisPengaduan jenis;
  final List<Color> colors;
  const _JenisData({
    required this.label,
    required this.emoji,
    required this.desc,
    required this.jenis,
    required this.colors,
  });
}

const List<_JenisData> _daftarJenis = [
  _JenisData(
    label: 'Infrastruktur',
    emoji: '🏗️',
    desc: 'Jalan rusak, jembatan, gedung desa',
    jenis: JenisPengaduan.infrastruktur,
    colors: [Color(0xFFf97316), Color(0xFFea580c)],
  ),
  _JenisData(
    label: 'Pelayanan Publik',
    emoji: '🏛️',
    desc: 'Administrasi, perizinan, pelayanan kantor',
    jenis: JenisPengaduan.pelayanan,
    colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
  ),
  _JenisData(
    label: 'Keamanan & Ketertiban',
    emoji: '🛡️',
    desc: 'Gangguan keamanan, ketertiban umum',
    jenis: JenisPengaduan.keamanan,
    colors: [Color(0xFFef4444), Color(0xFFdc2626)],
  ),
  _JenisData(
    label: 'Lingkungan Hidup',
    emoji: '🌿',
    desc: 'Sampah, pencemaran, penghijauan',
    jenis: JenisPengaduan.lingkungan,
    colors: [Color(0xFF22c55e), Color(0xFF16a34a)],
  ),
];

// ============================================================
//  HALAMAN UTAMA PENGADUAN
// ============================================================

class PengaduanPage extends StatefulWidget {
  const PengaduanPage({super.key});
  @override
  State<PengaduanPage> createState() => _PengaduanPageState();
}

class _PengaduanPageState extends State<PengaduanPage> {
  final _service = PengaduanService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onBottomNavTap(AppNavItem item) {
    if (item == AppNavItem.pengaduan) {
      return;
    }

    if (item == AppNavItem.beranda) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BerandaPage()),
      );
    } else if (item == AppNavItem.surat) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuratPage()),
      );
    } else if (item == AppNavItem.pengumuman) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PengumumanPage()),
      );
    } else if (item == AppNavItem.profil) {
      final authService = AuthService();
      if (authService.isLoggedIn && authService.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              user: authService.currentUser!,
              authService: authService,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color _statusColor(StatusPengaduan s) {
    switch (s) {
      case StatusPengaduan.menunggu:
        return const Color(0xFFd97706);
      case StatusPengaduan.diproses:
        return const Color(0xFF2563eb);
      case StatusPengaduan.selesai:
        return const Color(0xFF16a34a);
      case StatusPengaduan.ditolak:
        return const Color(0xFFdc2626);
    }
  }

  String _formatTgl(DateTime dt) {
    const b = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${b[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    _buildJenisSection(),
                    _buildRiwayatSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavItem.pengaduan,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF1e40af), Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x661e40af),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
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
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                  'Pengaduan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Sampaikan aspirasi Anda',
                  style: TextStyle(color: Color(0x99ffffff), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFeff6ff), Color(0xFFdbeafe)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFbfdbfe)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563eb).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('💡', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cara Menyampaikan Pengaduan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1e40af),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pilih kategori → isi form → lampirkan foto → kirim. Pantau status di riwayat.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3b82f6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Pengaduan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0f172a),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih kategori sesuai masalah Anda',
            style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            _daftarJenis.length,
            (i) => _buildJenisCard(_daftarJenis[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisCard(_JenisData d) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FormPengaduanPage(jenisData: d)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: d.colors[1].withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: d.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: d.colors[1].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(d.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    d.desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748b),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: d.colors),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatSection() {
    final list = _service.daftarPengaduan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Pengaduan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0f172a),
                  letterSpacing: -0.2,
                ),
              ),
              if (list.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563eb).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} pengaduan',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2563eb),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text('📭', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada pengaduan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0f172a),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih kategori di atas untuk memulai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94a3b8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ...list.map((p) => _buildRiwayatCard(p)),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(PengaduanItem p) {
    final color = _statusColor(p.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.jenisEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.judul,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0f172a),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${p.statusEmoji} ${p.statusLabel}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.deskripsi,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748b),
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Preview foto
          if (p.fotoPath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(p.fotoPath!),
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Color(0xFF94a3b8),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFf1f5f9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.jenisLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_today_rounded,
                size: 10,
                color: Color(0xFF94a3b8),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTgl(p.tanggalAjuan),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94a3b8)),
              ),
            ],
          ),

          if (p.catatanAdmin != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.catatanAdmin!,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
//  FORM PENGADUAN
// ============================================================

class FormPengaduanPage extends StatefulWidget {
  final _JenisData jenisData;
  const FormPengaduanPage({super.key, required this.jenisData});
  @override
  State<FormPengaduanPage> createState() => _FormPengaduanPageState();
}

class _FormPengaduanPageState extends State<FormPengaduanPage> {
  final _service = PengaduanService();
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _fotoPath;
  String? _fotoNama;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskCtrl.dispose();
    super.dispose();
  }

  // ── Ambil foto dari galeri via file_picker ─────────────────

  Future<void> _pilihDariGaleri() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _fotoPath = result.files.single.path;
          _fotoNama = result.files.single.name;
        });
      }
    } catch (_) {
      _showError('Gagal membuka galeri. Periksa izin aplikasi.');
    }
  }

  // ── Ambil foto dari kamera via image_picker ────────────────

  Future<void> _ambilDariKamera() async {
    try {
      final foto = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (foto != null) {
        setState(() {
          _fotoPath = foto.path;
          _fotoNama = foto.name;
        });
      }
    } catch (_) {
      _showError('Gagal membuka kamera. Periksa izin aplikasi.');
    }
  }

  void _showError(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), backgroundColor: const Color(0xFFdc2626)),
    );
  }

  // ── Bottom sheet pilih sumber foto ────────────────────────

  void _showPilihSumber() {
    final colors = widget.jenisData.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFe2e8f0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0f172a),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ambil foto baru atau pilih dari galeri',
              style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                // ── Kamera ──
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _ambilDariKamera();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors[1].withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kamera',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ambil foto baru',
                            style: TextStyle(
                              color: Color(0xCCffffff),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Galeri ──
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pilihDariGaleri();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFe2e8f0),
                          width: 1.5,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.photo_library_rounded,
                            color: Color(0xFF2563eb),
                            size: 30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Galeri',
                            style: TextStyle(
                              color: Color(0xFF2563eb),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih dari galeri',
                            style: TextStyle(
                              color: Color(0xFF94a3b8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    _service.tambahPengaduan(
      judul: _judulCtrl.text.trim(),
      deskripsi: _deskCtrl.text.trim(),
      jenis: widget.jenisData.jenis,
      fotoPath: _fotoPath,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 350),
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ade80), Color(0xFF16a34a)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16a34a).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('✅', style: TextStyle(fontSize: 34)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pengaduan Terkirim!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pengaduan Anda telah diterima dan akan segera ditindaklanjuti oleh perangkat desa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16a34a).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Lihat Riwayat',
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
    final colors = widget.jenisData.colors;
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[1].withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.jenisData.emoji} ${widget.jenisData.label}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Isi form dengan jelas dan lengkap',
                          style: TextStyle(
                            color: Color(0xCCffffff),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip kategori
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors[0].withOpacity(0.08),
                              colors[1].withOpacity(0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors[0].withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              widget.jenisData.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.jenisData.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: colors[1],
                                    ),
                                  ),
                                  Text(
                                    widget.jenisData.desc,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors[1].withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Judul
                      _label('Judul Pengaduan', required: true),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _judulCtrl,
                        hint: 'Contoh: Jalan Rusak di RT 03',
                        maxLines: 1,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Judul wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      _label('Deskripsi Pengaduan', required: true),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _deskCtrl,
                        hint:
                            'Jelaskan masalah secara detail: lokasi, waktu, dan dampaknya...',
                        maxLines: 5,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Deskripsi wajib diisi';
                          if (v.trim().length < 20)
                            return 'Deskripsi minimal 20 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Foto
                      _label('Foto Bukti', required: false),
                      const SizedBox(height: 8),
                      _buildFotoArea(colors),
                      const SizedBox(height: 28),

                      // Tombol Kirim
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSubmitting
                                  ? [
                                      const Color(0xFF94a3b8),
                                      const Color(0xFF64748b),
                                    ]
                                  : colors,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isSubmitting
                                            ? const Color(0xFF94a3b8)
                                            : colors[1])
                                        .withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Kirim Pengaduan',
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Area Foto ──────────────────────────────────────────────

  Widget _buildFotoArea(List<Color> colors) {
    // Sudah ada foto
    if (_fotoPath != null) {
      return Column(
        children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.file(
                  File(_fotoPath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                // Badge sukses
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16a34a),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Foto terpilih',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tombol hapus
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _fotoPath = null;
                      _fotoNama = null;
                    }),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Nama file
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFe2e8f0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file_rounded,
                  size: 15,
                  color: Color(0xFF64748b),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _fotoNama ?? 'foto_bukti',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tombol ganti
          GestureDetector(
            onTap: _showPilihSumber,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors[0].withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: colors[0], size: 17),
                  const SizedBox(width: 6),
                  Text(
                    'Ganti Foto',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors[0],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Belum ada foto
    return GestureDetector(
      onTap: _showPilihSumber,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors[0].withOpacity(0.1),
                    colors[1].withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                color: colors[0],
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap untuk lampirkan foto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors[0],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kamera atau Galeri  •  JPG, PNG',
              style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────────────

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0f172a),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFef4444),
              fontWeight: FontWeight.w900,
            ),
          ),
        ] else ...[
          const SizedBox(width: 6),
          const Text(
            '(opsional)',
            style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
          ),
        ],
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0f172a)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFcbd5e1)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
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
          borderSide: const BorderSide(color: Color(0xFF2563eb), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFef4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5),
        ),
      ),
    );
  }
}
