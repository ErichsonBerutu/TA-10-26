import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'beranda_page.dart';
import 'pengaduan_page.dart';
import 'profile_page.dart';
import 'surat_page.dart';

// ============================================================
//  MODEL
// ============================================================

class PengumumanData {
  final String id;
  final String judul;
  final String isi;
  final String? gambarUrl;
  final DateTime uploadedAt;
  final String uploadedBy;

  const PengumumanData({
    required this.id,
    required this.judul,
    required this.isi,
    this.gambarUrl,
    required this.uploadedAt,
    required this.uploadedBy,
  });
}

// ============================================================
//  DATA DUMMY
// ============================================================

final List<PengumumanData> _dummyPengumuman = [
  PengumumanData(
    id: '1',
    judul: 'Kegiatan Posyandu Bulan November 2025',
    isi:
        'Pelaksanaan posyandu bulanan untuk balita dan ibu hamil akan dilaksanakan di Balai Desa Hutabulu Mejan pada tanggal 25 November 2025 pukul 08.00 – 12.00 WIB. Warga diharapkan membawa buku KIA dan kartu posyandu masing-masing.',
    gambarUrl: 'assets/images/logo.png',
    uploadedAt: DateTime(2025, 11, 21, 9, 30),
    uploadedBy: 'Admin Desa',
  ),
  PengumumanData(
    id: '2',
    judul: 'Pelaksanaan Senam Pagi Remaja Setiap Minggu',
    isi:
        'Karang Taruna Desa Hutabulu Mejan mengadakan kegiatan senam pagi bersama setiap hari Minggu pukul 06.30 WIB di lapangan desa. Terbuka untuk seluruh warga terutama remaja usia 13–25 tahun.',
    gambarUrl: 'assets/images/example.png',
    uploadedAt: DateTime(2025, 11, 21, 10, 0),
    uploadedBy: 'Karang Taruna',
  ),
  PengumumanData(
    id: '3',
    judul: 'Pemberian Sembako Gratis oleh Kepala Desa',
    isi:
        'Kepala Desa Hutabulu Mejan akan membagikan paket sembako gratis kepada warga yang kurang mampu pada tanggal 28 November 2025. Harap melapor ke kantor desa paling lambat 26 November 2025.',
    uploadedAt: DateTime(2025, 11, 20, 14, 15),
    uploadedBy: 'Kepala Desa',
  ),
  PengumumanData(
    id: '4',
    judul: 'Gotong Royong Pembersihan Saluran Air',
    isi:
        'Seluruh warga diundang untuk berpartisipasi dalam gotong royong pembersihan saluran air pada hari Sabtu, 30 November 2025 pukul 07.00 WIB. Bawa peralatan kebersihan masing-masing.',
    uploadedAt: DateTime(2025, 11, 19, 8, 0),
    uploadedBy: 'Admin Desa',
  ),
  PengumumanData(
    id: '5',
    judul: 'Musyawarah Desa Penetapan APBDes 2026',
    isi:
        'Musyawarah Desa pembahasan APBDes 2026 akan dilaksanakan pada tanggal 5 Desember 2025 pukul 09.00 WIB di Aula Balai Desa. Seluruh perangkat desa dan perwakilan warga diundang hadir.',
    uploadedAt: DateTime(2025, 11, 18, 11, 30),
    uploadedBy: 'Sekretaris Desa',
  ),
  PengumumanData(
    id: '6',
    judul: 'Festival Budaya Lokal Desa Hutabulu Mejan',
    isi:
        'Festival Budaya Lokal akan diselenggarakan pada tanggal 10 Desember 2025 menampilkan pertunjukan seni daerah, lomba tradisional, pameran kuliner lokal, dan musik tradisional.',
    uploadedAt: DateTime(2025, 11, 17, 16, 0),
    uploadedBy: 'Panitia Festival',
  ),
];

// ============================================================
//  HALAMAN PENGUMUMAN
// ============================================================

class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  void _onBottomNavTap(AppNavItem item) {
    if (item == AppNavItem.pengumuman) {
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
    } else if (item == AppNavItem.pengaduan) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PengaduanPage()),
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
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime dt) {
    const bulan = [
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
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}, $jam.$menit WIB';
  }

  void _bukaDetail(PengumumanData data) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => _DetailPengumumanPage(data: data),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
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
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _dummyPengumuman.length,
                  itemBuilder: (_, i) => _buildCard(_dummyPengumuman[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavItem.pengumuman,
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
                  'Pengumuman',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Informasi terkini dari desa',
                  style: TextStyle(color: Color(0x99ffffff), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              '${_dummyPengumuman.length} info',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card: judul bold + datetime + tombol ───────────────────

  Widget _buildCard(PengumumanData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul bold
          Text(
            data.judul,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0f172a),
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),

          // Datetime
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Color(0xFF94a3b8),
              ),
              const SizedBox(width: 5),
              Text(
                _formatTanggal(data.uploadedAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pratinjau isi (2 baris)
          Text(
            data.isi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748b),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Tombol lihat selengkapnya
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _bukaDetail(data),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563eb).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selengkapnya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 15,
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
}

// ============================================================
//  HALAMAN DETAIL
// ============================================================

class _DetailPengumumanPage extends StatelessWidget {
  final PengumumanData data;
  const _DetailPengumumanPage({required this.data});

  void _bukaGambarFull(BuildContext context, String source) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullScreenImagePage(source: source)),
    );
  }

  Widget _buildGambarPengumuman(BuildContext context) {
    final source = data.gambarUrl;
    if (source == null || source.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');

    return GestureDetector(
      onTap: () => _bukaGambarFull(context, source),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetwork
                  ? Image.network(
                      source,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gambarFallback(),
                    )
                  : Image.asset(
                      source,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gambarFallback(),
                    ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap untuk zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gambarFallback() {
    return Container(
      color: const Color(0xFFe2e8f0),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Color(0xFF94a3b8),
          size: 34,
        ),
      ),
    );
  }

  String _formatTanggalLengkap(DateTime dt) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
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
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}  •  $jam.$menit WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1e3a8a),
                    Color(0xFF1e40af),
                    Color(0xFF2563eb),
                  ],
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
                          'Detail Pengumuman',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Informasi lengkap',
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

            // Konten
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul bold besar
                      Text(
                        data.judul,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0f172a),
                          height: 1.35,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Datetime + oleh
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Color(0xFF94a3b8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatTanggalLengkap(data.uploadedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94a3b8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: Color(0xFF94a3b8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            data.uploadedBy,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94a3b8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      const Divider(height: 1, color: Color(0xFFe2e8f0)),
                      const SizedBox(height: 18),

                      // Gambar pengumuman (jika tersedia)
                      _buildGambarPengumuman(context),
                      if (data.gambarUrl != null && data.gambarUrl!.isNotEmpty)
                        const SizedBox(height: 18),

                      // Isi lengkap
                      Text(
                        data.isi,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                          height: 1.85,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol kembali
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563eb,
                                ).withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Kembali',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
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
}

class _FullScreenImagePage extends StatelessWidget {
  final String source;

  const _FullScreenImagePage({required this.source});

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Pratinjau Gambar',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: isNetwork
              ? Image.network(
                  source,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white70,
                    size: 52,
                  ),
                )
              : Image.asset(
                  source,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white70,
                    size: 52,
                  ),
                ),
        ),
      ),
    );
  }
}
