// lib/pages/riwayat_page.dart
//
// Halaman untuk warga melihat riwayat pengajuan surat.
// - Status: Menunggu / Disetujui / Ditolak
// - Jika disetujui → bisa buka surat dari server (cetak/simpan)

import 'package:flutter/material.dart';
import '../services/pengajuan_service.dart';
import '../models/pengajuan_model.dart';
import 'pdf_preview_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  final _service = PengajuanService();
  late TabController _tabCtrl;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.muatDaftarPengajuan();
    });
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
                  final menunggu  = semua.where((p) =>
                    p.status == StatusPengajuan.menunggu ||
                    p.status == StatusPengajuan.diproses
                  ).toList();
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
      return RefreshIndicator(
        onRefresh: () => _service.muatDaftarPengajuan(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
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
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _service.muatDaftarPengajuan(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  // ── KARTU PENGAJUAN ────────────────────────────────────

  Widget _buildCard(PengajuanSurat p) {
    final (Color statusColor, Color statusBg, IconData statusIcon) =
        switch (p.status) {
      StatusPengajuan.menunggu  => (const Color(0xFFb45309), const Color(0xFFfef3c7), Icons.hourglass_empty_rounded),
      StatusPengajuan.diproses  => (const Color(0xFF1d4ed8), const Color(0xFFdbeafe), Icons.sync_rounded),
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
                      // Tampilkan nomor surat jika sudah disetujui
                      if (p.nomorSurat != null && p.nomorSurat!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.numbers_rounded, size: 11, color: Color(0xFF15803d)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'No. ${p.nomorSurat}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF15803d),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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

          // ── Tanggal respons (jika sudah direspons admin)
          if (p.tanggalRespons != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(
                    p.status == StatusPengajuan.disetujui
                        ? Icons.check_rounded
                        : p.status == StatusPengajuan.diproses
                            ? Icons.sync_rounded
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isOpening ? null : () => _bukaLetterDariServer(p),
                  icon: _isOpening
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: Text(
                    _isOpening ? 'Membuka...' : '🖨️  Lihat & Cetak Surat',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

          // ── Badge info status bawah kartu
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
          if (p.status == StatusPengajuan.diproses)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFeff6ff),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF93c5fd)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_rounded, size: 14, color: Color(0xFF2563eb)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengajuan Anda sedang diverifikasi oleh petugas desa. Harap tunggu.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF1d4ed8), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Buka Surat dari Server ─────────────────────────────

  Future<void> _bukaLetterDariServer(PengajuanSurat p) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(pengajuan: p),
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────────

  String _fmtTgl(DateTime dt) {
    const bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bln[dt.month]} ${dt.year}';
  }
}