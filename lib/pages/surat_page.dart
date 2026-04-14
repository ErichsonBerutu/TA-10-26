import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'beranda_page.dart';
import 'pengaduan_page.dart';
import 'pengumuman_page.dart';
import 'profile_page.dart';

// ============================================================
//  MODEL
// ============================================================

class JenisSurat {
  final String id;
  final String nama;
  final String emoji;
  final String deskripsi;
  final Color color;
  final List<FieldSurat> fields;

  const JenisSurat({
    required this.id,
    required this.nama,
    required this.emoji,
    required this.deskripsi,
    required this.color,
    required this.fields,
  });
}

class FieldSurat {
  final String id;
  final String label;
  final String hint;
  final FieldType type;
  final List<String> options; // untuk dropdown

  const FieldSurat({
    required this.id,
    required this.label,
    required this.hint,
    this.type = FieldType.text,
    this.options = const [],
  });
}

enum FieldType { text, number, date, dropdown, textarea }

// ============================================================
//  DATA JENIS SURAT
// ============================================================

final List<JenisSurat> daftarSurat = [
  JenisSurat(
    id: 'keterangan_domisili',
    nama: 'Surat Keterangan Domisili',
    emoji: '🏠',
    deskripsi: 'Keterangan tempat tinggal warga',
    color: const Color(0xFF2563eb),
    fields: [
      FieldSurat(
        id: 'nik',
        label: 'NIK',
        hint: 'Masukkan 16 digit NIK',
        type: FieldType.number,
      ),
      FieldSurat(
        id: 'nama',
        label: 'Nama Lengkap',
        hint: 'Masukkan nama lengkap',
      ),
      FieldSurat(
        id: 'ttl',
        label: 'Tempat, Tanggal Lahir',
        hint: 'Contoh: Medan, 01 Januari 2000',
      ),
      FieldSurat(
        id: 'jk',
        label: 'Jenis Kelamin',
        hint: 'Pilih jenis kelamin',
        type: FieldType.dropdown,
        options: ['Laki-laki', 'Perempuan'],
      ),
      FieldSurat(
        id: 'alamat',
        label: 'Alamat Lengkap',
        hint: 'Masukkan alamat sesuai KTP',
        type: FieldType.textarea,
      ),
      FieldSurat(
        id: 'keperluan',
        label: 'Keperluan',
        hint: 'Contoh: Melamar pekerjaan',
        type: FieldType.textarea,
      ),
    ],
  ),
  JenisSurat(
    id: 'keterangan_usaha',
    nama: 'Surat Keterangan Usaha',
    emoji: '🏪',
    deskripsi: 'Keterangan kepemilikan usaha warga',
    color: const Color(0xFF16a34a),
    fields: [
      FieldSurat(
        id: 'nik',
        label: 'NIK',
        hint: 'Masukkan 16 digit NIK',
        type: FieldType.number,
      ),
      FieldSurat(
        id: 'nama',
        label: 'Nama Pemilik',
        hint: 'Masukkan nama lengkap pemilik',
      ),
      FieldSurat(
        id: 'nama_usaha',
        label: 'Nama Usaha',
        hint: 'Masukkan nama usaha',
      ),
      FieldSurat(
        id: 'jenis_usaha',
        label: 'Jenis Usaha',
        hint: 'Pilih jenis usaha',
        type: FieldType.dropdown,
        options: [
          'Perdagangan',
          'Jasa',
          'Pertanian',
          'Peternakan',
          'Industri Rumahan',
          'Lainnya',
        ],
      ),
      FieldSurat(
        id: 'alamat_usaha',
        label: 'Alamat Usaha',
        hint: 'Masukkan alamat usaha',
        type: FieldType.textarea,
      ),
      FieldSurat(
        id: 'sejak',
        label: 'Usaha Berdiri Sejak',
        hint: 'Contoh: 01 Januari 2020',
      ),
    ],
  ),
  JenisSurat(
    id: 'keterangan_tidak_mampu',
    nama: 'Surat Keterangan Tidak Mampu',
    emoji: '📋',
    deskripsi: 'Keterangan kondisi ekonomi warga',
    color: const Color(0xFFea580c),
    fields: [
      FieldSurat(
        id: 'nik',
        label: 'NIK',
        hint: 'Masukkan 16 digit NIK',
        type: FieldType.number,
      ),
      FieldSurat(
        id: 'nama',
        label: 'Nama Lengkap',
        hint: 'Masukkan nama lengkap',
      ),
      FieldSurat(
        id: 'ttl',
        label: 'Tempat, Tanggal Lahir',
        hint: 'Contoh: Medan, 01 Januari 2000',
      ),
      FieldSurat(
        id: 'pekerjaan',
        label: 'Pekerjaan',
        hint: 'Masukkan pekerjaan',
      ),
      FieldSurat(
        id: 'penghasilan',
        label: 'Penghasilan Per Bulan',
        hint: 'Contoh: Rp 500.000',
        type: FieldType.number,
      ),
      FieldSurat(
        id: 'alamat',
        label: 'Alamat Lengkap',
        hint: 'Masukkan alamat sesuai KTP',
        type: FieldType.textarea,
      ),
      FieldSurat(
        id: 'keperluan',
        label: 'Keperluan',
        hint: 'Contoh: Beasiswa pendidikan',
        type: FieldType.textarea,
      ),
    ],
  ),
  JenisSurat(
    id: 'pengantar_nikah',
    nama: 'Surat Pengantar Nikah',
    emoji: '💍',
    deskripsi: 'Surat pengantar untuk keperluan pernikahan',
    color: const Color(0xFFdb2777),
    fields: [
      FieldSurat(
        id: 'nik',
        label: 'NIK',
        hint: 'Masukkan 16 digit NIK',
        type: FieldType.number,
      ),
      FieldSurat(
        id: 'nama',
        label: 'Nama Lengkap',
        hint: 'Masukkan nama lengkap',
      ),
      FieldSurat(
        id: 'ttl',
        label: 'Tempat, Tanggal Lahir',
        hint: 'Contoh: Medan, 01 Januari 2000',
      ),
      FieldSurat(
        id: 'agama',
        label: 'Agama',
        hint: 'Pilih agama',
        type: FieldType.dropdown,
        options: [
          'Islam',
          'Kristen Protestan',
          'Kristen Katolik',
          'Hindu',
          'Buddha',
          'Konghucu',
        ],
      ),
      FieldSurat(
        id: 'status',
        label: 'Status Perkawinan',
        hint: 'Pilih status',
        type: FieldType.dropdown,
        options: ['Belum Kawin', 'Duda', 'Janda'],
      ),
      FieldSurat(
        id: 'nama_pasangan',
        label: 'Nama Calon Pasangan',
        hint: 'Masukkan nama calon pasangan',
      ),
      FieldSurat(
        id: 'alamat',
        label: 'Alamat Lengkap',
        hint: 'Masukkan alamat sesuai KTP',
        type: FieldType.textarea,
      ),
    ],
  ),
  JenisSurat(
    id: 'keterangan_kelahiran',
    nama: 'Surat Keterangan Kelahiran',
    emoji: '👶',
    deskripsi: 'Keterangan kelahiran anak',
    color: const Color(0xFF0891b2),
    fields: [
      FieldSurat(
        id: 'nama_anak',
        label: 'Nama Anak',
        hint: 'Masukkan nama anak',
      ),
      FieldSurat(
        id: 'jk_anak',
        label: 'Jenis Kelamin Anak',
        hint: 'Pilih jenis kelamin',
        type: FieldType.dropdown,
        options: ['Laki-laki', 'Perempuan'],
      ),
      FieldSurat(
        id: 'tgl_lahir',
        label: 'Tanggal Lahir',
        hint: 'Contoh: 01 Januari 2025',
      ),
      FieldSurat(
        id: 'tempat_lahir',
        label: 'Tempat Lahir',
        hint: 'Contoh: Rumah Sakit / Rumah',
      ),
      FieldSurat(
        id: 'nama_ayah',
        label: 'Nama Ayah',
        hint: 'Masukkan nama ayah',
      ),
      FieldSurat(id: 'nama_ibu', label: 'Nama Ibu', hint: 'Masukkan nama ibu'),
      FieldSurat(
        id: 'alamat',
        label: 'Alamat Orang Tua',
        hint: 'Masukkan alamat lengkap',
        type: FieldType.textarea,
      ),
    ],
  ),
  JenisSurat(
    id: 'keterangan_kematian',
    nama: 'Surat Keterangan Kematian',
    emoji: '🕊️',
    deskripsi: 'Keterangan kematian warga',
    color: const Color(0xFF475569),
    fields: [
      FieldSurat(
        id: 'nama_almarhum',
        label: 'Nama Almarhum/Almarhumah',
        hint: 'Masukkan nama lengkap',
      ),
      FieldSurat(
        id: 'nik',
        label: 'NIK',
        hint: 'Masukkan 16 digit NIK',
        type: FieldType.number,
      ),
      FieldSurat(
        id: 'ttl',
        label: 'Tempat, Tanggal Lahir',
        hint: 'Contoh: Medan, 01 Januari 1960',
      ),
      FieldSurat(
        id: 'tgl_meninggal',
        label: 'Tanggal Meninggal',
        hint: 'Contoh: 01 Januari 2025',
      ),
      FieldSurat(
        id: 'tempat_meninggal',
        label: 'Tempat Meninggal',
        hint: 'Contoh: Rumah Sakit / Rumah',
      ),
      FieldSurat(
        id: 'penyebab',
        label: 'Penyebab Kematian',
        hint: 'Masukkan penyebab kematian',
      ),
      FieldSurat(
        id: 'pelapor',
        label: 'Nama Pelapor',
        hint: 'Masukkan nama pelapor',
      ),
      FieldSurat(
        id: 'hubungan',
        label: 'Hubungan dengan Almarhum',
        hint: 'Contoh: Anak, Suami, Istri',
      ),
    ],
  ),
];

// ============================================================
//  HALAMAN SURAT
// ============================================================

class SuratPage extends StatefulWidget {
  const SuratPage({super.key});

  @override
  State<SuratPage> createState() => _SuratPageState();
}

class _SuratPageState extends State<SuratPage> {
  void _pilihSurat(JenisSurat surat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormSuratPage(surat: surat)),
    );
  }

  void _onBottomNavTap(AppNavItem item) {
    if (item == AppNavItem.surat) {
      return;
    }

    if (item == AppNavItem.beranda) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BerandaPage()),
      );
    } else if (item == AppNavItem.pengaduan) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PengaduanPage()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBanner(),
                    _buildSectionTitle(),
                    _buildGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavItem.surat,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x402563eb),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Layanan Surat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Info ──────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e40af), Color(0xFF3b82f6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x302563eb),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('📄', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permohonan Surat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pilih jenis surat yang Anda butuhkan, lalu isi formulir dengan data yang benar.',
                  style: TextStyle(
                    color: Color(0xFFbfdbfe),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        'Pilih Jenis Surat',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1e293b),
        ),
      ),
    );
  }

  // ── Grid Kartu Surat ─────────────────────────────────────

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daftarSurat.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95, // ← ubah dari 1.1 menjadi 0.95
        ),
        itemBuilder: (_, i) => _buildCard(daftarSurat[i]),
      ),
    );
  }

  Widget _buildCard(JenisSurat surat) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pilihSurat(surat),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: surat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    surat.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                surat.nama,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e293b),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                surat.deskripsi,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94a3b8),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: surat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ajukan →',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: surat.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  HALAMAN FORM SURAT
// ============================================================

class FormSuratPage extends StatefulWidget {
  final JenisSurat surat;

  const FormSuratPage({super.key, required this.surat});

  @override
  State<FormSuratPage> createState() => _FormSuratPageState();
}

class _FormSuratPageState extends State<FormSuratPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.surat.fields) {
      if (field.type == FieldType.dropdown) {
        _dropdownValues[field.id] = null;
      } else {
        _controllers[field.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFdcfce7),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Permohonan Terkirim!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Permohonan ${widget.surat.nama} Anda telah berhasil dikirim. Harap tunggu konfirmasi dari pihak desa.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748b),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali ke Menu Surat',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormBanner(),
                      const SizedBox(height: 20),
                      ...widget.surat.fields.map((f) => _buildField(f)),
                      const SizedBox(height: 8),
                      _buildSubmitButton(),
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

  // ── Header Form ──────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.surat.color.withOpacity(0.9), widget.surat.color],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.surat.color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.surat.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.surat.nama,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Form ──────────────────────────────────────────

  Widget _buildFormBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.surat.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.surat.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: widget.surat.color, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pastikan data yang Anda isi sudah benar dan sesuai dengan KTP.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field Builder ────────────────────────────────────────

  Widget _buildField(FieldSurat field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          if (field.type == FieldType.dropdown)
            _buildDropdown(field)
          else if (field.type == FieldType.textarea)
            _buildTextArea(field)
          else
            _buildTextField(field),
        ],
      ),
    );
  }

  Widget _buildTextField(FieldSurat field) {
    return TextFormField(
      controller: _controllers[field.id],
      keyboardType: field.type == FieldType.number
          ? TextInputType.number
          : TextInputType.text,
      decoration: _inputDecoration(field.hint),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '${field.label} wajib diisi' : null,
    );
  }

  Widget _buildTextArea(FieldSurat field) {
    return TextFormField(
      controller: _controllers[field.id],
      maxLines: 3,
      decoration: _inputDecoration(field.hint),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '${field.label} wajib diisi' : null,
    );
  }

  Widget _buildDropdown(FieldSurat field) {
    return DropdownButtonFormField<String>(
      value: _dropdownValues[field.id],
      decoration: _inputDecoration(field.hint),
      items: field.options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _dropdownValues[field.id] = v),
      validator: (v) => v == null ? '${field.label} wajib dipilih' : null,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.surat.color, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFef4444)),
      ),
    );
  }

  // ── Submit Button ────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.surat.color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Kirim Permohonan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
      ),
    );
  }
}
