import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_config/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/pengajuan_service.dart' as pengajuan_service;
import 'beranda_page.dart' show BerandaPage;
import 'pengaduan_page.dart';
import 'pengumuman_page.dart';
import 'form_pengajuan_surat_page.dart';

// ============================================================
//  MODEL
// ============================================================

class JenisSurat {
  final String id;
  final String nama;
  final String? serverName;
  final String emoji;
  final String deskripsi;
  final Color color;
  final List<FieldSurat> fields;

  const JenisSurat({
    required this.id,
    required this.nama,
    this.serverName,
    required this.emoji,
    required this.deskripsi,
    required this.color,
    required this.fields,
  });

  String get effectiveServerName => serverName ?? nama;
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
  List<dynamic> _dynamicSurat = [];
  bool _isLoadingDynamic = true;
  String? _dynamicError;

  @override
  void initState() {
    super.initState();
    _fetchDynamicSurat();
  }

  Future<void> _fetchDynamicSurat() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDynamic = true;
      _dynamicError = null;
    });

    try {
      final token = AuthService().token;
      if (token == null) {
        setState(() {
          _isLoadingDynamic = false;
          _dynamicError = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/dynamic/jenis-surat');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null) {
          setState(() {
            _dynamicSurat = body['data'];
            _isLoadingDynamic = false;
          });
        } else {
          setState(() {
            _dynamicError = body['message'] ?? 'Gagal memuat surat dinamis.';
            _isLoadingDynamic = false;
          });
        }
      } else {
        setState(() {
          _dynamicError = 'Gagal memuat data dari server (${response.statusCode}).';
          _isLoadingDynamic = false;
        });
      }
    } catch (e) {
      setState(() {
        _dynamicError = 'Koneksi terputus. Periksa jaringan internet.';
        _isLoadingDynamic = false;
      });
      debugPrint('Error fetch dynamic surat: $e');
    }
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
      // TODO: Import ProfilePage dan AuthService sesuai kebutuhan
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
              child: RefreshIndicator(
                onRefresh: _fetchDynamicSurat,
                color: const Color(0xFF2563eb),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBanner(),
                      _buildUnifiedSectionHeader(),
                      _buildUnifiedSuratGrid(),
                    ],
                  ),
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

  /// Header tunggal untuk semua layanan surat
  Widget _buildUnifiedSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Layanan Surat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1e293b),
            ),
          ),
          if (!_isLoadingDynamic)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF2563eb)),
              onPressed: _fetchDynamicSurat,
              tooltip: 'Segarkan data',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  /// Grid terpadu: semua surat dari API — mekanisme identik untuk semua jenis surat
  Widget _buildUnifiedSuratGrid() {
    if (_isLoadingDynamic) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563eb)),
        ),
      );
    }

    if (_dynamicError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFfef2f2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFfee2e2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat layanan surat:\n$_dynamicError',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991b1b), height: 1.5),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _fetchDynamicSurat,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (_dynamicSurat.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFf1f5f9)),
        ),
        child: Column(
          children: const [
            Text('📋', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'Belum ada layanan surat tersedia.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748b),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Admin desa belum menambahkan jenis surat. Hubungi perangkat desa untuk informasi lebih lanjut.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8), height: 1.5),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _dynamicSurat.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (_, i) => _buildSuratCard(_dynamicSurat[i]),
      ),
    );
  }

  /// Kartu surat terpadu — digunakan untuk SEMUA jenis surat (lama & baru)
  Widget _buildSuratCard(Map<String, dynamic> surat) {
    int id = 0;
    final rawId = surat['id_jenis_surat'] ?? surat['id'];
    if (rawId is int) {
      id = rawId;
    } else if (rawId != null) {
      id = int.tryParse(rawId.toString()) ?? 0;
    }

    final String nama = surat['nama_surat'] ?? 'Surat';
    final String deskripsi =
        surat['deskripsi'] ?? surat['deskripsi_surat'] ?? 'Layanan surat desa';
    final String emoji = _getEmojiForSurat(nama);
    final Color color = _getColorForSurat(nama);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (id == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID surat tidak valid, coba refresh.')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormPengajuanSuratPage(
                jenisSuratId: id,
                namaSurat: nama,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nama,
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
                deskripsi,
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ajukan →',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
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

  String _getEmojiForSurat(String namaSurat) {
    final lower = namaSurat.toLowerCase();
    if (lower.contains('domisili')) return '🏠';
    if (lower.contains('usaha')) return '🏪';
    if (lower.contains('tidak mampu') || lower.contains('sktm')) return '📋';
    if (lower.contains('nikah') || lower.contains('pernikahan')) return '💍';
    if (lower.contains('lahir') || lower.contains('kelahiran')) return '👶';
    if (lower.contains('mati') || lower.contains('kematian') || lower.contains('meninggal')) return '🕊️';
    return '📝';
  }

  Color _getColorForSurat(String namaSurat) {
    final lower = namaSurat.toLowerCase();
    if (lower.contains('domisili')) return const Color(0xFF2563eb);
    if (lower.contains('usaha')) return const Color(0xFF16a34a);
    if (lower.contains('tidak mampu') || lower.contains('sktm')) return const Color(0xFFea580c);
    if (lower.contains('nikah') || lower.contains('pernikahan')) return const Color(0xFFdb2777);
    if (lower.contains('lahir') || lower.contains('kelahiran')) return const Color(0xFF0891b2);
    if (lower.contains('mati') || lower.contains('kematian') || lower.contains('meninggal')) return const Color(0xFF475569);
    return const Color(0xFF8b5cf6);
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
  String? _jenisSuratLookupError;

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

    // Kumpulkan semua nilai dari form
    final Map<String, String> formData = {};
    for (final entry in _controllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) formData[entry.key] = val;
    }
    for (final entry in _dropdownValues.entries) {
      if (entry.value != null) formData[entry.key] = entry.value!;
    }

    final authService = AuthService();
    final token = authService.token;
    final currentRole = authService.currentUser?.role;

    if (token == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Anda harus login terlebih dahulu agar pengajuan dapat dikirim.',
      );
      return;
    }

    if (currentRole != 'masyarakat') {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Akun saat ini bukan masyarakat. Login sebagai akun masyarakat untuk mengajukan surat.',
      );
      return;
    }

    final jenisSuratId = await _resolveJenisSuratId(
      widget.surat.effectiveServerName,
    );
    if (jenisSuratId == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = _jenisSuratLookupError != null
          ? 'Tidak dapat menemukan jenis surat di server. $_jenisSuratLookupError'
          : 'Tidak dapat menemukan jenis surat di server. Pastikan backend aktif dan jenis surat telah tersedia.';
      _showErrorDialog(message);
      return;
    }

    final success = await _submitSuratToApi(jenisSuratId, formData, token);
    if (!mounted) return;

    if (!success) {
      setState(() => _isSubmitting = false);
      _showErrorDialog(
        'Gagal mengirim pengajuan surat. Periksa koneksi internet atau konfigurasi API.',
      );
      return;
    }

    // Simpan juga ke state lokal agar antarmuka riwayat tetap responsif.
    pengajuan_service.PengajuanService().tambahPengajuan(
      jenisSurat: widget.surat.nama,
      emoji: widget.surat.emoji,
      data: formData,
    );

    setState(() => _isSubmitting = false);
    _showSuccessDialog();
  }

  Future<int?> _resolveJenisSuratId(String jenisSuratNama) async {
    _jenisSuratLookupError = null;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/jenis-surat');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AuthService().token}',
        },
      );

      if (response.statusCode != 200) {
        final bodyText = response.body;
        _jenisSuratLookupError =
            'Status ${response.statusCode}. Pastikan token valid dan role masyarakat. Response: $bodyText';
        debugPrint(
          'Jenis surat lookup failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map || body['status'] != true) {
        _jenisSuratLookupError =
            'Server merespons data tidak valid. Response: ${response.body}';
        debugPrint('Jenis surat lookup invalid response: $body');
        return null;
      }

      final jenisList = body['data'] as List<dynamic>?;
      if (jenisList == null) return null;

      final expectedName = jenisSuratNama.trim().toLowerCase();
      int? fallbackId;
      String? fallbackName;

      for (final item in jenisList) {
        if (item is Map<String, dynamic>) {
          final nama = (item['nama_surat'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (nama == expectedName) {
            return item['id_jenis_surat'] as int?;
          }
          if (fallbackId == null &&
              (nama.contains(expectedName) || expectedName.contains(nama))) {
            fallbackId = item['id_jenis_surat'] as int?;
            fallbackName = nama;
          }
        }
      }

      if (fallbackId != null) {
        debugPrint(
          'Jenis surat fallback match: "$expectedName" -> "$fallbackName"',
        );
        return fallbackId;
      }

      _jenisSuratLookupError =
          'Nama surat "${widget.surat.nama}" tidak ditemukan di daftar jenis surat server.';
    } catch (e) {
      _jenisSuratLookupError = 'Gagal menghubungi server: $e';
      debugPrint('Resolve jenis surat error: $e');
    }
    return null;
  }

  Future<bool> _submitSuratToApi(
    int jenisSuratId,
    Map<String, String> formData,
    String token,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/surat');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_jenis_surat': jenisSuratId,
          'data_form': formData,
        }),
      );

      debugPrint(
        'Submit surat response: ${response.statusCode} ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Submit surat error: $e');
      return false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kesalahan'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
