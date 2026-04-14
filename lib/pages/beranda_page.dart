import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/auth_service.dart';
import 'pengumuman_page.dart';
import 'surat_page.dart';
import 'pengaduan_page.dart';
import 'profile_page.dart';

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
  LayananItem(label: 'Data', emoji: '🗂️', color: Color(0xFF7c3aed)),
  LayananItem(label: 'Pengumuman', emoji: '📣', color: Color(0xFF16a34a)),
];

const List<PengumumanItem> pengumumanList = [
  PengumumanItem(
    title: 'Kegiatan Posyandu di Desa',
    desc:
        'Pelaksanaan posyandu bulanan untuk balita dan ibu hamil di balai desa.',
    date: '21 November 2025',
    emoji: '🏥',
  ),
  PengumumanItem(
    title: 'Pelaksanaan Senam Remaja',
    desc: 'Kegiatan senam pagi bersama untuk para remaja desa setiap minggu.',
    date: '21 November 2025',
    emoji: '🏃',
  ),
  PengumumanItem(
    title: 'Pemberian Sembako Oleh Kades',
    desc: 'Program bantuan sembako dari kepala desa untuk warga kurang mampu.',
    date: '21 November 2025',
    emoji: '🛒',
  ),
];

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
  final _service = PengajuanService();
  OverlayEntry? _overlayEntry;
  bool _notifOpen = false;

  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _pulse;
  late Animation<double> _float;

  // Untuk efek press scale pada slide dan layanan
  int? _pressedSlide;
  int? _pressedLayanan;

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);

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

    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _nextSlide());
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    _overlayEntry?.remove();
    _timer?.cancel();
    _pageController.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _nextSlide() {
    final next = (_activeSlide + 1) % slides.length;
    _goToSlide(next);
  }

  void _prevSlide() {
    final prev = (_activeSlide - 1 + slides.length) % slides.length;
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

  void _toggleNotif() {
    if (_notifOpen) {
      _closeNotif();
    } else {
      _openNotif();
    }
  }

  void _openNotif() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _notifOpen = true);
  }

  void _closeNotif() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _notifOpen = false);
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeNotif,
        child: Stack(
          children: [
            // Backdrop gelap
            Container(color: Colors.black.withOpacity(0.35)),
            // Panel notifikasi
            Positioned(
              top: 62, // disesuaikan dengan tinggi header 56
              right: 16,
              width: size.width - 32,
              child: GestureDetector(
                onTap: () {}, // cegah close saat tap panel
                child: _buildNotifPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifPanel() {
    final notifikasi = _service.notifikasi;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header panel
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                  ),
                  if (_service.jumlahBelumDibaca > 0)
                    GestureDetector(
                      onTap: () {
                        _service.bacaSemuaNotifikasi();
                        _overlayEntry?.markNeedsBuild();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFeff6ff),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Baca Semua',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2563eb),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _closeNotif,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFf1f5f9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF64748b),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFf1f5f9)),

            // Isi notifikasi
            if (notifikasi.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Text('🔕', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada notifikasi',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8)),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifikasi.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFf1f5f9),
                  ),
                  itemBuilder: (_, i) => _buildNotifItem(notifikasi[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem(NotifikasiItem item) {
    final isApprove = item.jenis == JenisNotifikasi.disetujui;
    final isTolak = item.jenis == JenisNotifikasi.ditolak;
    final Color color = isApprove
        ? const Color(0xFF16a34a)
        : isTolak
        ? const Color(0xFFdc2626)
        : const Color(0xFF2563eb);

    return GestureDetector(
      onTap: () {
        _service.bacaNotifikasi(item.id);
        _overlayEntry?.markNeedsBuild();

        if (isApprove && item.pengajuanId != null) {
          final pengajuan = _service.getPengajuanById(item.pengajuanId!);
          if (pengajuan != null) {
            _closeNotif();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfPreviewPage(pengajuan: pengajuan),
              ),
            );
          }
        }
      },
      child: Container(
        color: item.sudahDibaca ? Colors.transparent : color.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isApprove
                      ? '✅'
                      : isTolak
                      ? '❌'
                      : 'ℹ️',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.judul,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      if (!item.sudahDibaca)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.pesan,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748b),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isApprove) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16a34a).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 10,
                            color: Color(0xFF16a34a),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Tap untuk unduh PDF',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF16a34a),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              child: SingleChildScrollView(
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
                        _notifOpen
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                      ),
                      if (_service.jumlahBelumDibaca > 0)
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
                                '${_service.jumlahBelumDibaca}',
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
                onPageChanged: (i) => setState(() => _activeSlide = i),
                itemCount: slides.length,
                itemBuilder: (_, i) => _buildSlide(slides[i], i),
              ),
              // Left vignette
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Right vignette
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
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
              // Bottom label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        slides[_activeSlide].emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        slides[_activeSlide].label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(slides.length, (i) {
          final active = i == _activeSlide;
          final accent = _slideAccents[_activeSlide] ?? const Color(0xFF2563eb);
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
      child: Row(
        children: [
          _statItem('1.2K', 'Penduduk', '👥'),
          _statDivider(),
          _statItem('430', 'KK', '🏠'),
          _statDivider(),
          _statItem('12', 'RT/RW', '📍'),
          _statDivider(),
          _statItem('98%', 'Terdata', '✅'),
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
            child: Column(
              children: List.generate(pengumumanList.length, (i) {
                return Column(
                  children: [
                    _buildPengumumanItem(pengumumanList[i], i),
                    if (i < pengumumanList.length - 1)
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

  Widget _buildPengumumanItem(PengumumanItem item, int index) {
    final badgeColor = _pengumumanBadgeColors[index] ?? const Color(0xFF2563eb);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: index == 0
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : index == pengumumanList.length - 1
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        onTap: () {},
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
                child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
                      item.desc,
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
                          item.date,
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
}
