// lib/pages/riwayat_page.dart
//
// Halaman untuk warga melihat riwayat pengajuan surat.
// - Status: Menunggu / Disetujui / Ditolak
// - Jika disetujui → bisa langsung download PDF

import 'package:flutter/material.dart';
import '../services/pengajuan_service.dart';
import '../services/pdf_service.dart';
import '../models/pengajuan_model.dart';
import 'pdf_preview_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  final _service    = PengajuanService();
  final _pdfService = PdfService();
  late TabController _tabCtrl;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: AnimatedBuilder(
                animation: _service,
                builder: (_, __) {
                  final semua     = _service.daftarPengajuan;
                  final menunggu  = semua.where((p) => p.status == StatusPengajuan.menunggu).toList();
                  final disetujui = semua.where((p) => p.status == StatusPengajuan.disetujui).toList();
                  final ditolak   = semua.where((p) => p.status == StatusPengajuan.ditolak).toList();
                  return TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(semua),
                      _buildList(menunggu),
                      _buildList(disetujui),
                      _buildList(ditolak),
                    ],
                  );
                },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x402563eb), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.history_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Riwayat Pengajuan Surat',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1e40af),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: [
          _tab('Semua', Icons.list_rounded),
          _tab('Menunggu', Icons.hourglass_empty_rounded),
          _tab('Disetujui', Icons.check_circle_rounded),
          _tab('Ditolak', Icons.cancel_rounded),
        ],
      ),
    );
  }

  Tab _tab(String label, IconData icon) =>
      Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label),
      ]));

  // ── LIST VIEW ──────────────────────────────────────────

  Widget _buildList(List<PengajuanSurat> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
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
              'Belum ada pengajuan',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748b)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajukan surat baru melalui menu Surat',
              style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  // ── KARTU PENGAJUAN ────────────────────────────────────

  Widget _buildCard(PengajuanSurat p) {
    final (Color statusColor, Color statusBg, IconData statusIcon) =
        switch (p.status) {
      StatusPengajuan.menunggu  => (const Color(0xFFb45309), const Color(0xFFfef3c7), Icons.hourglass_empty_rounded),
      StatusPengajuan.disetujui => (const Color(0xFF15803d), const Color(0xFFdcfce7), Icons.check_circle_rounded),
      StatusPengajuan.ditolak   => (const Color(0xFFb91c1c), const Color(0xFFfee2e2), Icons.cancel_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Info utama
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji jenis surat
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff6ff),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(p.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.jenisSurat,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.id,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94a3b8)),
                          const SizedBox(width: 3),
                          Text(
                            'Diajukan ${_fmtTgl(p.tanggalAjuan)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        p.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Alasan tolak (jika ditolak)
          if (p.status == StatusPengajuan.ditolak && p.alasanTolak != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFfef2f2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFfca5a5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFdc2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan penolakan: ${p.alasanTolak}',
                      style: const TextStyle(
                        fontSize: 12, color: Color(0xFFb91c1c), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // ── Tanggal respons (jika sudah diproses)
          if (p.tanggalRespons != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(
                    p.status == StatusPengajuan.disetujui
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Direspons ${_fmtTgl(p.tanggalRespons!)}',
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),

          // ── Tombol aksi (jika disetujui)
          if (p.status == StatusPengajuan.disetujui)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PdfPreviewPage(pengajuan: p)),
                      ),
                      icon: const Icon(Icons.visibility_rounded, size: 15),
                      label: const Text('Preview', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563eb),
                        side: const BorderSide(color: Color(0xFF2563eb)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : () => _download(p),
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 15),
                      label: Text(
                        _isDownloading ? 'Memproses...' : 'Download PDF',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16a34a),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Divider bawah
          if (p.status == StatusPengajuan.menunggu)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFfffbeb),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFfcd34d)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFd97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengajuan Anda sedang menunggu persetujuan dari perangkat desa.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF92400e), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Download PDF ───────────────────────────────────────

  Future<void> _download(PengajuanSurat p) async {
    setState(() => _isDownloading = true);
    try {
      await _pdfService.downloadSurat(context, p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh PDF: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ── Helper ─────────────────────────────────────────────

  String _fmtTgl(DateTime dt) {
    const bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bln[dt.month]} ${dt.year}';
  }
}