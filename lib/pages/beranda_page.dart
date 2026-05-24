import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/notifikasi_service.dart';
import '../services/berita_service.dart';
import '../services/pengumuman_service.dart' as svc_pengumuman;
import 'notifikasi_page.dart';
import 'pengumuman_page.dart';
import 'surat_page.dart';
import 'pengaduan_page.dart';
import 'profile_page.dart';
import 'arsip_page.dart';

// ============================================================
//  MODEL DATA
// ============================================================

class SlideItem {
  final String label;
  final String emoji;
  final String desc;
  final List<Color> colors;

  const SlideItem({
    required this.label,
    required this.emoji,
    required this.desc,
    required this.colors,
  });
}

class LayananItem {
  final String label;
  final String emoji;
  final Color color;

  const LayananItem({
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class PengumumanItem {
  final String title;
  final String desc;
  final String date;
  final String emoji;

  const PengumumanItem({
    required this.title,
    required this.desc,
    required this.date,
    required this.emoji,
  });
}

enum JenisNotifikasi { disetujui, ditolak, informasi }

class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final JenisNotifikasi jenis;
  final bool sudahDibaca;
  final String? pengajuanId;

  const NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.jenis,
    this.sudahDibaca = false,
    this.pengajuanId,
  });
}

class PengajuanItem {
  final String id;
  final String judul;
  final String status;

  const PengajuanItem({
    required this.id,
    required this.judul,
    required this.status,
  });
}

// ============================================================
//  STYLING TAMBAHAN (Map terpisah — tidak sentuh model asli)
// ============================================================

// Deskripsi detail untuk setiap slide carousel
const Map<int, String> _slideDetail = {
  0: 'Informasi kegiatan pertanian desa, jadwal panen, dan program ketahanan pangan.',
  1: 'Jadwal posyandu, imunisasi, dan program kesehatan ibu & anak di desa.',
  2: 'Kegiatan gotong royong bersama warga untuk membangun desa yang lebih baik.',
  3: 'Pelestarian seni budaya dan tradisi lokal sebagai warisan leluhur desa.',
};

const Map<int, List<Color>> _slideGradients = {
  0: [Color(0xFF4ade80), Color(0xFF16a34a), Color(0xFF166534)],
  1: [Color(0xFF60a5fa), Color(0xFF2563eb), Color(0xFF1e3a8a)],
  2: [Color(0xFFfb923c), Color(0xFFea580c), Color(0xFF7c2d12)],
  3: [Color(0xFFc084fc), Color(0xFF9333ea), Color(0xFF4c1d95)],
};

const Map<int, Color> _slideAccents = {
  0: Color(0xFF166534),
  1: Color(0xFF1e3a8a),
  2: Color(0xFF7c2d12),
  3: Color(0xFF4c1d95),
};

const Map<int, IconData> _layananIcons = {
  0: Icons.description_rounded,
  1: Icons.chat_bubble_rounded,
  2: Icons.folder_rounded,
  3: Icons.campaign_rounded,
};

const Map<int, List<Color>> _layananGradients = {
  0: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
  1: [Color(0xFFf87171), Color(0xFFdc2626)],
  2: [Color(0xFFa78bfa), Color(0xFF7c3aed)],
  3: [Color(0xFF4ade80), Color(0xFF16a34a)],
};

const Map<int, Color> _pengumumanBadgeColors = {
  0: Color(0xFF2563eb),
  1: Color(0xFF16a34a),
  2: Color(0xFFd97706),
};

class PengajuanService extends ChangeNotifier {
  final List<NotifikasiItem> _notifikasi = [];
  final List<PengajuanItem> _pengajuan = [];

  List<NotifikasiItem> get notifikasi => _notifikasi;
  int get jumlahBelumDibaca => _notifikasi.where((n) => !n.sudahDibaca).length;

  void addNotifikasi(NotifikasiItem item) {
    _notifikasi.insert(0, item);
    notifyListeners();
  }

  void bacaNotifikasi(String id) {
    final index = _notifikasi.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifikasi[index] = NotifikasiItem(
        id: _notifikasi[index].id,
        judul: _notifikasi[index].judul,
        pesan: _notifikasi[index].pesan,
        jenis: _notifikasi[index].jenis,
        sudahDibaca: true,
        pengajuanId: _notifikasi[index].pengajuanId,
      );
      notifyListeners();
    }
  }

  void bacaSemuaNotifikasi() {
    for (int i = 0; i < _notifikasi.length; i++) {
      _notifikasi[i] = NotifikasiItem(
        id: _notifikasi[i].id,
        judul: _notifikasi[i].judul,
        pesan: _notifikasi[i].pesan,
        jenis: _notifikasi[i].jenis,
        sudahDibaca: true,
        pengajuanId: _notifikasi[i].pengajuanId,
      );
    }
    notifyListeners();
  }

  PengajuanItem? getPengajuanById(String id) {
    try {
      return _pengajuan.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

// ============================================================
//  PDF PREVIEW PAGE (PLACEHOLDER)
// ============================================================

class PdfPreviewPage extends StatelessWidget {
  final PengajuanItem pengajuan;

  const PdfPreviewPage({required this.pengajuan, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pengajuan.judul)),
      body: Center(child: Text('PDF Preview: ${pengajuan.judul}')),
    );
  }
}

// ============================================================
//  DATA  (tidak ada perubahan dari versi asli)
// ============================================================

const List<SlideItem> slides = [
  SlideItem(
    label: 'Kegiatan Pertanian',
    emoji: '🌾',
    desc: 'Petani bekerja di sawah hijau',
    colors: [Color(0xFF4ade80), Color(0xFF166534)],
  ),
  SlideItem(
    label: 'Kegiatan Posyandu',
    emoji: '🏥',
    desc: 'Pelayanan kesehatan masyarakat',
    colors: [Color(0xFF60a5fa), Color(0xFF1e3a8a)],
  ),
  SlideItem(
    label: 'Gotong Royong',
    emoji: '🤝',
    desc: 'Kebersamaan warga desa',
    colors: [Color(0xFFf97316), Color(0xFF7c2d12)],
  ),
  SlideItem(
    label: 'Budaya Lokal',
    emoji: '🎭',
    desc: 'Pelestarian budaya desa',
    colors: [Color(0xFFa78bfa), Color(0xFF4c1d95)],
  ),
];

const List<LayananItem> layananList = [
  LayananItem(label: 'Surat', emoji: '📋', color: Color(0xFF2563eb)),
  LayananItem(label: 'Pengaduan', emoji: '💬', color: Color(0xFFef4444)),
  LayananItem(label: 'Riwayat & Arsip', emoji: '📂', color: Color(0xFF7c3aed)),
  LayananItem(label: 'Pengumuman', emoji: '📣', color: Color(0xFF16a34a)),
];

// Dummy pengumumanList telah dihapus agar murni bersumber dari API backend.

// ============================================================
//  HALAMAN BERANDA
// ============================================================

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with TickerProviderStateMixin {
  int _activeSlide = 0;
  Timer? _timer;
  final PageController _pageController = PageController();
  final _service = PengajuanService();        // lokal untuk animasi beranda
  final _notifSvc = NotifikasiService();       // real notifikasi dari server
  final _beritaSvc = BeritaService();          // real berita dari server
  final _pengumumanSvc = svc_pengumuman.PengumumanService(); // real pengumuman dari server

  List<dynamic> get _carouselItems {
    if (_beritaSvc.daftar.isNotEmpty) {
      // Hanya ambil berita yang memiliki keterangan waktu (hasTimestamp == true)
      final listWithTime = _beritaSvc.daftar.where((item) => item.hasTimestamp).toList();
      // Urutkan berdasarkan tanggal terbaru (descending)
      listWithTime.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Batasi maksimal 5 berita terbaru
      final limited = listWithTime.length > 5 ? listWithTime.sublist(0, 5) : listWithTime;
      if (limited.isNotEmpty) {
        return limited;
      }
    }
    return slides;
  }

  List<dynamic> get _berandaPengumuman {
    final list = _pengumumanSvc.daftar;
    return list.length > 3 ? list.sublist(0, 3) : list;
  }

  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _pulse;
  late Animation<double> _float;

  int? _pressedSlide;
  int? _pressedLayanan;

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
    _notifSvc.addListener(_refresh);
    _beritaSvc.addListener(_refresh);
    _pengumumanSvc.addListener(_refresh);

    // Fetch notifikasi, berita, & pengumuman dari server saat beranda dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifSvc.startPeriodicFetch(intervalSeconds: 10);
      _beritaSvc.muatBerita(forceRefresh: true);
      _pengumumanSvc.muatPengumuman(forceRefresh: true);
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _nextSlide());
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    _notifSvc.removeListener(_refresh);
    _beritaSvc.removeListener(_refresh);
    _pengumumanSvc.removeListener(_refresh);
    _notifSvc.stopPeriodicFetch();
    _timer?.cancel();
    _pageController.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _nextSlide() {
    final items = _carouselItems;
    if (items.isEmpty) return;
    final next = (_activeSlide + 1) % items.length;
    _goToSlide(next);
  }

  void _prevSlide() {
    final items = _carouselItems;
    if (items.isEmpty) return;
    final prev = (_activeSlide - 1 + items.length) % items.length;
    _goToSlide(prev);
  }

  void _goToSlide(int index) {
    setState(() => _activeSlide = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _refresh() => setState(() {});

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

  void _toggleNotif() {
    // Navigasi ke halaman notifikasi penuh (server-synced)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotifikasiPage()),
    ).then((_) {
      // Refresh badge setelah kembali
      _notifSvc.loadNotifikasi(forceRefresh: true);
    });
  }

  // ──────────────────────────────────────────────────────────
  //  SLIDE DETAIL BOTTOM SHEET
  // ──────────────────────────────────────────────────────────

  void _showSlideDetail(int index) {
    final slide = slides[index];
    final gradColors = _slideGradients[index] ?? slide.colors;
    final detail = _slideDetail[index] ?? slide.desc;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFe2e8f0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Hero banner mini
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      slide.emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0f172a),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748b),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradColors),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gradColors.last.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Lihat Selengkapnya',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  LAYANAN NAVIGATION
  // ──────────────────────────────────────────────────────────

  void _onLayananTap(LayananItem item, int index) {
    if (item.label == 'Surat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuratPage()),
      );
    } else if (item.label == 'Pengaduan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PengaduanPage()),
      );
    } else if (item.label == 'Riwayat & Arsip' || item.label == 'Data') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ArsipPage()),
      );
    } else if (item.label == 'Pengumuman') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PengumumanPage()),
      );
    }
  }

  void _onBottomNavTap(AppNavItem item) {
    if (item == AppNavItem.beranda) {
      return;
    }

    if (item == AppNavItem.surat) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuratPage()),
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

  // ──────────────────────────────────────────────────────────
  //  INFO DIALOG
  // ──────────────────────────────────────────────────────────

  void _showInfoDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
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
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1e40af).withOpacity(0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563eb).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏡', style: TextStyle(fontSize: 34)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Hutabulu Mejan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0f172a),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Sistem Administrasi Kependudukan Desa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: Column(
                    children: [
                      _dialogRow(
                        Icons.location_on_rounded,
                        'Desa Hutabulu Mejan',
                        const Color(0xFFef4444),
                      ),
                      const SizedBox(height: 10),
                      _dialogRow(
                        Icons.phone_rounded,
                        '+62 812 3456 7890',
                        const Color(0xFF16a34a),
                      ),
                      const SizedBox(height: 10),
                      _dialogRow(
                        Icons.access_time_rounded,
                        'Senin – Jumat, 08.00 – 16.00',
                        const Color(0xFFd97706),
                      ),
                      const SizedBox(height: 10),
                      _dialogRow(
                        Icons.email_rounded,
                        'desa@hutabulumejan.go.id',
                        const Color(0xFF2563eb),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Versi 1.0.0',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                        'Tutup',
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

  Widget _dialogRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────

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
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _notifSvc.loadNotifikasi(forceRefresh: true),
                    _beritaSvc.muatBerita(forceRefresh: true),
                    _pengumumanSvc.muatPengumuman(forceRefresh: true),
                  ]);
                },
                color: const Color(0xFF2563eb),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeBanner(),
                      _buildCarousel(),
                      _buildDots(),
                      _buildLayananSection(),
                      _buildStatsBanner(),
                      _buildPengumumanSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavItem.beranda,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            transform: GradientRotation(2.6179938779914944),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1e40af).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 255, 255, 255),
                          Color.fromARGB(255, 255, 255, 255),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.3 + _pulse.value * 0.35),
                          blurRadius: 8 + _pulse.value * 10,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Hutabulu Mejan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: _showInfoDialog,
                  child: _headerGlassBtn(Icons.info_outline_rounded),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleNotif,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _headerGlassBtn(
                        Icons.notifications_none_rounded,
                      ),
                      if (_notifSvc.jumlahBelumDibaca > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFef4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1e40af),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _notifSvc.jumlahBelumDibaca > 9
                                    ? '9+'
                                    : '${_notifSvc.jumlahBelumDibaca}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
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
          ],
        ),
      ),
    );
  }

  Widget _headerGlassBtn(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WELCOME BANNER
  // ──────────────────────────────────────────────────────────

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563eb).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff6ff),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFbfdbfe)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563eb),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'BERANDA',
                        style: TextStyle(
                          color: Color(0xFF2563eb),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selamat Datang,\nWarga Desa! 👋',
                  style: TextStyle(
                    color: Color(0xFF0f172a),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Layanan administrasi desa\ndi ujung jari Anda',
                  style: TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text('🏘️', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  CAROUSEL
  // ──────────────────────────────────────────────────────────

  Widget _buildCarousel() {
    final items = _carouselItems;

    if (_beritaSvc.isLoading && _beritaSvc.daftar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563eb).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563eb)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 190,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  if (items.isNotEmpty) {
                    setState(() => _activeSlide = i % items.length);
                  }
                },
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  if (item is SlideItem) {
                    return _buildSlide(item, i);
                  } else {
                    return _buildBeritaSlide(item as BeritaItem, i);
                  }
                },
              ),
              // Left vignette (IgnorePointer agar tap menembus ke gambar berita)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right vignette (IgnorePointer agar tap menembus ke gambar berita)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _carouselBtn(Icons.chevron_left_rounded, _prevSlide),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _carouselBtn(Icons.chevron_right_rounded, _nextSlide),
                ),
              ),
              // Bottom label (IgnorePointer agar tap menembus ke gambar berita)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _carouselEmoji(_activeSlide),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _carouselLabel(_activeSlide),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
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
      ),
    );
  }

  String _carouselEmoji(int index) {
    final items = _carouselItems;
    if (items.isEmpty || index >= items.length) return '📰';
    final item = items[index];
    if (item is SlideItem) return item.emoji;
    return '📰';
  }

  String _carouselLabel(int index) {
    final items = _carouselItems;
    if (items.isEmpty || index >= items.length) return '';
    final item = items[index];
    if (item is SlideItem) return item.label;
    return item.judul;
  }

  Widget _buildSlide(SlideItem slide, int index) {
    final gradColors = _slideGradients[index] ?? slide.colors;
    final isPressed = _pressedSlide == index;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedSlide = index),
      onTapUp: (_) {
        setState(() => _pressedSlide = null);
        _showSlideDetail(index);
      },
      onTapCancel: () => setState(() => _pressedSlide = null),
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, __) => AnimatedScale(
          scale: isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -25,
                  left: -25,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                // Tap hint badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedOpacity(
                    opacity: isPressed ? 0.5 : 0.9,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _float.value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slide.emoji, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 8),
                        Text(
                          slide.desc,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildBeritaSlide(BeritaItem berita, int index) {
    final isPressed = _pressedSlide == index;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedSlide = index),
      onTapUp: (_) {
        setState(() => _pressedSlide = null);
        _showBeritaDetail(berita);
      },
      onTapCancel: () => setState(() => _pressedSlide = null),
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, __) => AnimatedScale(
          scale: isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1e3a8a), Color(0xFF1e40af), Color(0xFF3b82f6)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image berita jika ada gambar
                if (berita.gambarUrl != null && berita.gambarUrl!.isNotEmpty)
                  Image.network(
                    berita.gambarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF1e40af),
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 48),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF1e40af),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                          ),
                        ),
                      );
                    },
                  ),
                // Overlay gelap di atas gambar berita agar tulisan terbaca
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Bubble dekoratif jika tidak ada gambar
                if (berita.gambarUrl == null || berita.gambarUrl!.isEmpty) ...[
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -25,
                    left: -25,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                ],
                // Tag "BERITA DESA" di pojok kiri atas
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563eb).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'BERITA DESA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tag "Baca" di kanan atas
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedOpacity(
                    opacity: isPressed ? 0.5 : 0.9,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Baca',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Deskripsi di tengah jika tidak ada gambar
                if (berita.gambarUrl == null || berita.gambarUrl!.isEmpty)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, _float.value),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📰', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              berita.judul,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
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
      ),
    );
  }

  void _showBeritaDetail(BeritaItem berita) {
    final hasImage = berita.gambarUrl != null && berita.gambarUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 16),
            // Hero banner berita
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1e3a8a), Color(0xFF2563eb)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        berita.gambarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 60),
                        ),
                      )
                    else
                      const Center(
                        child: Text('📰', style: TextStyle(fontSize: 70)),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${berita.createdAt.day}/${berita.createdAt.month}/${berita.createdAt.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      berita.judul,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0f172a),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pembatas tipis
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color(0xFFf1f5f9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      berita.deskripsi,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1e3a8a), Color(0xFF2563eb)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563eb).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Selesai Membaca',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carouselBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  DOTS
  // ──────────────────────────────────────────────────────────

  Widget _buildDots() {
    final items = _carouselItems;
    if (items.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(items.length, (i) {
          final active = i == _activeSlide;
          Color accent = const Color(0xFF2563eb);
          if (items[i] is SlideItem) {
            accent = _slideAccents[_activeSlide] ?? const Color(0xFF2563eb);
          } else {
            accent = const Color(0xFF2563eb);
          }
          return GestureDetector(
            onTap: () => _goToSlide(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? accent : const Color(0xFFcbd5e1),
                borderRadius: BorderRadius.circular(4),
                boxShadow: active
                    ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  LAYANAN
  // ──────────────────────────────────────────────────────────

  Widget _buildLayananSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Desa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0f172a),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: List.generate(
              layananList.length,
              (i) => _buildLayananCard(layananList[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0f172a),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
            ),
          ],
        ),
        GestureDetector(
          onTap:
              onTap ??
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PengumumanPage()),
              ),
          child: const Text(
            'Lihat Semua →',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2563eb),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayananCard(LayananItem item, int index) {
    final gradColors =
        _layananGradients[index] ?? [item.color.withOpacity(0.7), item.color];
    final icon = _layananIcons[index] ?? Icons.apps_rounded;
    final isPressed = _pressedLayanan == index;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedLayanan = index),
      onTapUp: (_) {
        setState(() => _pressedLayanan = null);
        _onLayananTap(item, index);
      },
      onTapCancel: () => setState(() => _pressedLayanan = null),
      child: AnimatedScale(
        scale: isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradColors[1].withOpacity(isPressed ? 0.15 : 0.3),
                blurRadius: isPressed ? 4 : 10,
                offset: Offset(0, isPressed ? 2 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  STATS BANNER
  // ──────────────────────────────────────────────────────────

  Widget _buildStatsBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF1e40af), Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1e40af).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, String emoji) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.18),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  PENGUMUMAN
  // ──────────────────────────────────────────────────────────

  Widget _buildPengumumanSection() {
    final list = _berandaPengumuman;

    if (_pengumumanSvc.isLoading && _pengumumanSvc.daftar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Pengumuman',
              'Informasi terkini dari desa',
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1e40af).withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563eb)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Pengumuman',
            'Informasi terkini dari desa',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengumumanPage()),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1e40af).withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: list.isEmpty ? const EdgeInsets.symmetric(vertical: 28, horizontal: 16) : EdgeInsets.zero,
            child: list.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFf1f5f9),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '📭',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Belum ada pengumuman aktif',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tarik ke bawah untuk memuat ulang data terbaru',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: List.generate(list.length, (i) {
                      return Column(
                        children: [
                          _buildPengumumanItem(list[i], i),
                          if (i < list.length - 1)
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Color(0xFFf1f5f9),
                            ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPengumumanItem(dynamic item, int index) {
    final list = _berandaPengumuman;
    final badgeColor = _pengumumanBadgeColors[index % _pengumumanBadgeColors.length] ?? const Color(0xFF2563eb);
    
    String judul = '';
    String deskripsi = '';
    String tanggal = '';
    String? gambarUrl;
    Widget leadingWidget;

    if (item is PengumumanItem) {
      // Dummy data
      judul = item.title;
      deskripsi = _stripHtml(item.desc);
      tanggal = item.date;
      leadingWidget = Center(
        child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
      );
    } else {
      // Real data dari server
      final realItem = item as svc_pengumuman.PengumumanItem;
      judul = realItem.judul;
      deskripsi = _stripHtml(realItem.isi);
      tanggal = '${realItem.createdAt.day}/${realItem.createdAt.month}/${realItem.createdAt.year}';
      gambarUrl = realItem.gambarUrl;

      if (gambarUrl != null && gambarUrl.isNotEmpty) {
        leadingWidget = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            gambarUrl,
            fit: BoxFit.cover,
            width: 48,
            height: 48,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.campaign_rounded, color: Color(0xFF2563eb), size: 22),
            ),
          ),
        );
      } else {
        leadingWidget = const Center(
          child: Icon(Icons.campaign_rounded, color: Color(0xFF2563eb), size: 22),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: index == 0
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : index == list.length - 1
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        onTap: () {
          if (item is svc_pengumuman.PengumumanItem) {
            _showPengumumanDetail(item);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: badgeColor.withOpacity(0.2)),
                ),
                child: leadingWidget,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0f172a),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748b),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tanggal,
                          style: TextStyle(
                            fontSize: 10,
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFf1f5f9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94a3b8),
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPengumumanDetail(svc_pengumuman.PengumumanItem pengumuman) {
    final hasImage = pengumuman.gambarUrl != null && pengumuman.gambarUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        pengumuman.gambarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 60),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.campaign_rounded, color: Colors.white, size: 70),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pengumuman.createdAt.day}/${pengumuman.createdAt.month}/${pengumuman.createdAt.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pengumuman.judul,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0f172a),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Diterbitkan oleh: ${pengumuman.namaPembuat}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748b),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color(0xFFf1f5f9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _stripHtml(pengumuman.isi),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                              color: const Color(0xFF16a34a).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Tutup Pengumuman',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
