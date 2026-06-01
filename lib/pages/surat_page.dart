import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/offline_database_service.dart';
import 'beranda_page.dart' show BerandaPage;
import 'pengaduan_page.dart';
import 'pengumuman_page.dart';
import 'form_pengajuan_surat_page.dart';

// ============================================================
//  HALAMAN SURAT (DYNAMIC API-DRIVEN FLOW)
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
    
    // 1. Ambil data dari cache lokal terlebih dahulu (Local-First Read)
    final localData = await OfflineDatabaseService().ambilJenisSurat();
    if (localData.isNotEmpty) {
      setState(() {
        _dynamicSurat = localData;
        _isLoadingDynamic = false;
        _dynamicError = null;
      });
    } else {
      setState(() {
        _isLoadingDynamic = true;
        _dynamicError = null;
      });
    }

    try {
      final token = AuthService().token;
      if (token == null) {
        setState(() {
          _isLoadingDynamic = false;
          _dynamicError = _dynamicSurat.isNotEmpty ? null : 'Token tidak ditemukan. Silakan login ulang.';
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null) {
          final List rawData = body['data'];
          setState(() {
            _dynamicSurat = rawData;
            _isLoadingDynamic = false;
            _dynamicError = null;
          });
          
          // 2. Simpan data terbaru ke cache lokal
          final List<Map<String, dynamic>> cacheList = rawData
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          await OfflineDatabaseService().simpanJenisSurat(cacheList);
        } else {
          setState(() {
            _dynamicError = _dynamicSurat.isNotEmpty ? null : (body['message'] ?? 'Gagal memuat surat dinamis.');
            _isLoadingDynamic = false;
          });
        }
      } else {
        setState(() {
          _dynamicError = _dynamicSurat.isNotEmpty ? null : 'Gagal memuat data dari server (${response.statusCode}).';
          _isLoadingDynamic = false;
        });
      }
    } catch (e) {
      setState(() {
        // Jika data dari cache sudah ada, jangan tampilkan error layar kosong!
        _dynamicError = _dynamicSurat.isNotEmpty ? null : 'Koneksi terputus. Periksa jaringan internet.';
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
