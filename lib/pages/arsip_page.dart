// lib/pages/arsip_page.dart
//
// Halaman Arsip Terpadu ("Pertinggal") untuk warga mengakses semua berkas pelayanan:
// 1. Surat Kependudukan (📋) - List surat resmi desa yang pernah diajukan
// 2. Pengaduan Warga (💬) - List laporan pengaduan beserta tanggapan admin & resi PDF
//
// Mengintegrasikan:
// - PengajuanService & PengaduanService
// - PdfService untuk print native PDF
// - Image resolver untuk mengatasi file lokal vs server image path

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/pengajuan_service.dart';
import '../services/pengaduan_service.dart';
import '../services/pdf_service.dart';
import '../models/pengajuan_model.dart' as model_pengajuan;
import '../models/pengaduan_model.dart' as model_pengaduan;
import '../api_config/api_config.dart';
import 'pdf_preview_page.dart';
import 'pengaduan_detail_page.dart';

class ArsipPage extends StatefulWidget {
  const ArsipPage({super.key});

  @override
  State<ArsipPage> createState() => _ArsipPageState();
}

class _ArsipPageState extends State<ArsipPage>
    with SingleTickerProviderStateMixin {
  final _pengajuanSvc = PengajuanService();
  final _pengaduanSvc = PengaduanService();
  late TabController _tabController;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pengajuanSvc.addListener(_onServiceUpdate);
    _pengaduanSvc.addListener(_onServiceUpdate);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _pengajuanSvc.removeListener(_onServiceUpdate);
    _pengaduanSvc.removeListener(_onServiceUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAllData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        _pengajuanSvc.muatDaftarPengajuan(),
        _pengaduanSvc.muatRiwayatPengaduan(),
      ]);
    } catch (e) {
      debugPrint('ERROR _loadAllData: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _resolveFotoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Remove /api from base url to get root domain
    final baseDomain = ApiConfig.baseUrl.replaceAll('/api', '');
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseDomain/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSuratTab(),
                  _buildPengaduanTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331e40af),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arsip Berkas Digital',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pertinggal data surat & pengaduan Anda',
                  style: TextStyle(
                    color: Color(0xFFbfdbfe),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF2563eb),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3.5,
        labelColor: const Color(0xFF1e40af),
        unselectedLabelColor: const Color(0xFF64748b),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_rounded, size: 16),
                SizedBox(width: 8),
                Text('Surat'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_rounded, size: 16),
                SizedBox(width: 8),
                Text('Pengaduan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SURAT TAB ──────────────────────────────────────────

  Widget _buildSuratTab() {
    final list = _pengajuanSvc.daftarPengajuan;

    if (list.isEmpty) {
      return _buildEmptyState(
        'Belum Ada Pengajuan Surat',
        'Semua berkas pengajuan surat Anda akan diarsipkan di sini setelah Anda mengajukannya.',
        '📋',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF2563eb),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final p = list[index];
          return _buildSuratCard(p);
        },
      ),
    );
  }

  Widget _buildSuratCard(model_pengajuan.PengajuanSurat p) {
    final (Color statusColor, Color statusBg, String statusText) =
        switch (p.status) {
      model_pengajuan.StatusPengajuan.menunggu => (
          const Color(0xFFd97706),
          const Color(0xFFfffbeb),
          'Menunggu'
        ),
      model_pengajuan.StatusPengajuan.diproses => (
          const Color(0xFF2563eb),
          const Color(0xFFeff6ff),
          'Diproses'
        ),
      model_pengajuan.StatusPengajuan.disetujui => (
          const Color(0xFF16a34a),
          const Color(0xFFf0fdf4),
          'Disetujui'
        ),
      model_pengajuan.StatusPengajuan.ditolak => (
          const Color(0xFFdc2626),
          const Color(0xFFfef2f2),
          'Ditolak'
        ),
    };

    final isDisetujui = p.status == model_pengajuan.StatusPengajuan.disetujui;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTgl(p.tanggalAjuan),
                  style: const TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFeff6ff),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.jenisSurat,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF0f172a),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No. Registrasi: ${p.id}',
                            style: const TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Show applicant name / NIK if present (mirip layout admin web)
                          if (p.data.containsKey('nama') || p.data.containsKey('nik')) ...[
                            Text(
                              '${p.data['nama'] ?? '-'}',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NIK: ${p.data['nik'] ?? '-'}',
                              style: const TextStyle(
                                color: Color(0xFF64748b),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (p.status == model_pengajuan.StatusPengajuan.ditolak &&
                    p.alasanTolak != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfff5f5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFfee2e2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFdc2626), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alasan Penolakan: ${p.alasanTolak}',
                            style: const TextStyle(
                              color: Color(0xFF991b1b),
                              fontSize: 11.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons
                if (isDisetujui) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfPreviewPage(pengajuan: p),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                          label: const Text(
                            'Buka & Cetak PDF',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16a34a),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PENGADUAN TAB ──────────────────────────────────────

  Widget _buildPengaduanTab() {
    final list = _pengaduanSvc.daftarPengaduan;

    if (list.isEmpty) {
      return _buildEmptyState(
        'Belum Ada Pengaduan',
        'Semua berkas pelaporan pengaduan warga yang Anda kirim akan diarsipkan di sini.',
        '💬',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF2563eb),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final p = list[index];
          return _buildPengaduanCard(p);
        },
      ),
    );
  }

  Widget _buildPengaduanCard(model_pengaduan.PengaduanItem p) {
    final (Color statusColor, Color statusBg, String statusText) =
        switch (p.status) {
      model_pengaduan.StatusPengaduan.menunggu => (
          const Color(0xFFb45309),
          const Color(0xFFfef3c7),
          'Menunggu'
        ),
      model_pengaduan.StatusPengaduan.diproses => (
          const Color(0xFF2563eb),
          const Color(0xFFeff6ff),
          'Terbaca'
        ),
      model_pengaduan.StatusPengaduan.selesai => (
          const Color(0xFF16a34a),
          const Color(0xFFf0fdf4),
          'Berhasil'
        ),
      model_pengaduan.StatusPengaduan.ditolak => (
          const Color(0xFFdc2626),
          const Color(0xFFfef2f2),
          'Ditolak'
        ),
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PengaduanDetailPage(pengaduan: p)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTgl(p.tanggalAjuan),
                  style: const TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFfef2f2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          p.jenisEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.judul,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF0f172a),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Kategori: ${p.jenisLabel}',
                            style: const TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.deskripsi,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),

                // Complaint Attachment Image Parser
                _buildComplaintImage(p.fotoPath),

                // Admin Responses/Notes
                if (p.catatanAdmin != null && p.catatanAdmin!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFe2e8f0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded,
                                color: Color(0xFF475569), size: 15),
                            const SizedBox(width: 6),
                            const Text(
                              'Tanggapan Perangkat Desa:',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            if (p.tanggalRespons != null)
                              Text(
                                _formatTgl(p.tanggalRespons!),
                                style: const TextStyle(
                                  color: Color(0xFF94a3b8),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.catatanAdmin!,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action download PDF receipt
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await PdfService().downloadComplaint(context, p);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengunduh resi: $e'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.receipt_long_rounded, size: 15),
                        label: const Text(
                          'Unduh Bukti Resi PDF',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 11.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1e40af),
                          side: const BorderSide(
                              color: Color(0xFFbfdbfe), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildComplaintImage(String? path) {
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    final fullUrl = _resolveFotoUrl(path);

    // Check if it's a local file path
    final isLocalFile = !path.startsWith('http://') &&
        !path.startsWith('https://') &&
        !path.contains('storage/');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFf1f5f9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFcbd5e1), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: isLocalFile
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Color(0xFF94a3b8), size: 36),
                ),
              )
            : Image.network(
                fullUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Color(0xFF94a3b8), size: 36),
                ),
              ),
      ),
    );
  }

  // ── COMMON WIDGETS ─────────────────────────────────────

  Widget _buildEmptyState(String title, String desc, String emoji) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1e293b),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748b),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTgl(DateTime dt) {
    const bln = [
      '',
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
      'Des'
    ];
    return '${dt.day} ${bln[dt.month]} ${dt.year}';
  }
}
