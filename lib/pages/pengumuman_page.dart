import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/pengumuman_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'beranda_page.dart' hide PengumumanItem;
import 'pengaduan_page.dart';
import 'profile_page.dart';
import 'surat_page.dart';

// ============================================================
//  HALAMAN PENGUMUMAN — Terhubung ke Backend API
// ============================================================

class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage>
    with SingleTickerProviderStateMixin {
  final _svc = PengumumanService();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Navigation ────────────────────────────────────────────

  void _onBottomNavTap(AppNavItem item) {
    if (item == AppNavItem.pengumuman) return;

    if (item == AppNavItem.beranda) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const BerandaPage()));
    } else if (item == AppNavItem.surat) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SuratPage()));
    } else if (item == AppNavItem.pengaduan) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PengaduanPage()));
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
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
      }
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Muat data dari API
    _svc.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _svc.muatPengumuman();
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_refresh);
    _animCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  // ── Navigasi ke Detail ────────────────────────────────────

  void _bukaDetail(PengumumanItem data) {
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

  // ── Helpers ───────────────────────────────────────────────

  String _formatTanggal(DateTime dt) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final jam = dt.hour.toString().padLeft(2, '0');
    final mnt = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}, $jam.$mnt WIB';
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavItem.pengumuman,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

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
              color: Color(0x661e40af), blurRadius: 16, offset: Offset(0, 4)),
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
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
                      fontSize: 18),
                ),
                Text('Informasi terkini dari desa',
                    style: TextStyle(color: Color(0x99ffffff), fontSize: 11)),
              ],
            ),
          ),
          // Badge jumlah
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              _svc.isLoading ? '...' : '${_svc.total} info',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────

  Widget _buildBody() {
    if (_svc.isLoading) {
      return _buildLoading();
    }

    if (_svc.hasError) {
      return _buildError();
    }

    if (_svc.daftar.isEmpty) {
      return _buildEmpty();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: () => _svc.muatPengumuman(forceRefresh: true),
        color: const Color(0xFF2563eb),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _svc.daftar.length,
          itemBuilder: (_, i) => _buildCard(_svc.daftar[i]),
        ),
      ),
    );
  }

  // ── Loading State ─────────────────────────────────────────

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 4,
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(height: 16, width: double.infinity),
          const SizedBox(height: 8),
          _shimmer(height: 12, width: 160),
          const SizedBox(height: 10),
          _shimmer(height: 12, width: double.infinity),
          const SizedBox(height: 4),
          _shimmer(height: 12, width: 220),
        ],
      ),
    );
  }

  Widget _shimmer({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFe2e8f0),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFfee2e2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('📡', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Pengumuman',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b)),
            ),
            const SizedBox(height: 8),
            Text(
              _svc.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _svc.muatPengumuman(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: () => _svc.muatPengumuman(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2e8f0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('📭', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada pengumuman',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748b)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tarik ke bawah untuk memuat ulang',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────

  // Warna badge acak berdasarkan id pengumuman
  static const _badgeColors = [
    Color(0xFF2563eb),
    Color(0xFF16a34a),
    Color(0xFFd97706),
    Color(0xFF9333ea),
    Color(0xFFdc2626),
  ];

  Color _badgeColor(String id) {
    final idx = id.hashCode.abs() % _badgeColors.length;
    return _badgeColors[idx];
  }

  Widget _buildCard(PengumumanItem data) {
    final badge = _badgeColor(data.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _bukaDetail(data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail gambar (jika ada)
                if (data.gambarUrl != null && data.gambarUrl!.isNotEmpty)
                  _buildThumbnail(data.gambarUrl!),

                // Badge + judul
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badge.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📣',
                        style: TextStyle(fontSize: 13, color: badge),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.judul,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0f172a),
                          height: 1.35,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Meta: tanggal + pembuat
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: Color(0xFF94a3b8)),
                    const SizedBox(width: 4),
                    Text(
                      _formatTanggal(data.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94a3b8)),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.person_outline_rounded,
                        size: 11, color: Color(0xFF94a3b8)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        data.namaPembuat,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94a3b8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Pratinjau isi (2 baris)
                Text(
                  _stripHtml(data.isi),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol selengkapnya
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563eb).withValues(alpha: 0.25),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 14),
                      ],
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

  Widget _buildThumbnail(String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFe2e8f0),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded,
              color: Color(0xFF94a3b8), size: 32),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF2563eb), strokeWidth: 2),
              ),
      ),
    );
  }
}

// ============================================================
//  HALAMAN DETAIL PENGUMUMAN
// ============================================================

class _DetailPengumumanPage extends StatelessWidget {
  final PengumumanItem data;
  const _DetailPengumumanPage({required this.data});

  void _bukaGambarFull(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullScreenImagePage(url: url)),
    );
  }

  String _formatTanggalLengkap(DateTime dt) {
    const hari = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final jam = dt.hour.toString().padLeft(2, '0');
    final mnt = dt.minute.toString().padLeft(2, '0');
    return '${hari[dt.weekday - 1]}, ${dt.day} ${bulan[dt.month - 1]} ${dt.year}  •  $jam.$mnt WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1e3a8a),
                    Color(0xFF1e40af),
                    Color(0xFF2563eb)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x661e40af),
                      blurRadius: 16,
                      offset: Offset(0, 4)),
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
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
                              fontSize: 18),
                        ),
                        Text('Informasi lengkap',
                            style: TextStyle(
                                color: Color(0x99ffffff), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Konten ────────────────────────────────────────
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
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

                      // Meta
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: Color(0xFF94a3b8)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formatTanggalLengkap(data.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94a3b8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 13, color: Color(0xFF94a3b8)),
                          const SizedBox(width: 5),
                          Text(
                            data.namaPembuat,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94a3b8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0xFFe2e8f0)),
                      const SizedBox(height: 18),

                      // Gambar (jika ada)
                      if (data.gambarUrl != null &&
                          data.gambarUrl!.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () =>
                              _bukaGambarFull(context, data.gambarUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    data.gambarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFe2e8f0),
                                      child: const Center(
                                        child: Icon(
                                            Icons.broken_image_rounded,
                                            color: Color(0xFF94a3b8),
                                            size: 34),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in_rounded,
                                              color: Colors.white, size: 13),
                                          SizedBox(width: 4),
                                          Text('Tap untuk zoom',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Isi pengumuman
                      Text(
                        _stripHtml(data.isi),
                        textAlign: TextAlign.justify,
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
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563eb)
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 17),
                                SizedBox(width: 7),
                                Text(
                                  'Kembali',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
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

// ============================================================
//  FULLSCREEN IMAGE VIEWER
// ============================================================

class _FullScreenImagePage extends StatelessWidget {
  final String url;
  const _FullScreenImagePage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pratinjau Gambar',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 60),
            ),
          ),
        ),
      ),
    );
  }
}

String _stripHtml(String htmlString) {
  String parsed = htmlString.replaceAll(RegExp(r'<br\s*/?>'), '\n');
  parsed = parsed.replaceAll(RegExp(r'</p>'), '\n\n');
  parsed = parsed.replaceAll(RegExp(r'</div>|</li>|</h1>|</h2>|</h3>|</h4>|</h5>|</h5>'), '\n');
  parsed = parsed.replaceAll(RegExp(r'<[^>]*>'), '');
  parsed = parsed.replaceAll('&nbsp;', ' ');
  parsed = parsed.replaceAll('&amp;', '&');
  parsed = parsed.replaceAll('&lt;', '<');
  parsed = parsed.replaceAll('&gt;', '>');
  parsed = parsed.replaceAll('&quot;', '"');
  parsed = parsed.replaceAll('&#39;', "'");
  parsed = parsed.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return parsed.trim();
}
