// lib/pages/admin_pengajuan_page.dart
//
// Panel Admin — Kepala Desa / Perangkat Desa
// Fitur:
//   - Lihat semua pengajuan surat warga
//   - Approve → surat otomatis dibuat, warga bisa download
//   - Tolak   → dengan alasan penolakan
//   - Statistik ringkasan di header

import 'package:flutter/material.dart';
import '../services/pengajuan_service.dart';
import '../models/pengajuan_model.dart';

class AdminPengajuanPage extends StatefulWidget {
  const AdminPengajuanPage({super.key});

  @override
  State<AdminPengajuanPage> createState() => _AdminPengajuanPageState();
}

class _AdminPengajuanPageState extends State<AdminPengajuanPage>
    with SingleTickerProviderStateMixin {
  final _service = PengajuanService();
  late TabController _tabCtrl;

  static const _purple      = Color(0xFF7c3aed);
  static const _purpleDark  = Color(0xFF5b21b6);
  static const _green       = Color(0xFF16a34a);
  static const _red         = Color(0xFFdc2626);
  static const _amber       = Color(0xFFd97706);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
            AnimatedBuilder(
              animation: _service,
              builder: (_, __) => _buildStats(),
            ),
            _buildTabBar(),
            Expanded(
              child: AnimatedBuilder(
                animation: _service,
                builder: (_, __) {
                  final semua     = _service.daftarPengajuan;
                  final menunggu  = semua.where((p) => p.status == StatusPengajuan.menunggu).toList();
                  final disetujui = semua.where((p) => p.status == StatusPengajuan.disetujui).toList();
                  return TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(menunggu, showActions: true),
                      _buildList(disetujui, showActions: false),
                      _buildList(semua, showActions: false, showStatusBadge: true),
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
          colors: [_purpleDark, _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x507c3aed), blurRadius: 12, offset: Offset(0, 3)),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel Admin',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  'Manajemen Pengajuan Surat',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STATISTIK ──────────────────────────────────────────

  Widget _buildStats() {
    final semua     = _service.daftarPengajuan;
    final menunggu  = semua.where((p) => p.status == StatusPengajuan.menunggu).length;
    final disetujui = semua.where((p) => p.status == StatusPengajuan.disetujui).length;
    final ditolak   = semua.where((p) => p.status == StatusPengajuan.ditolak).length;

    return Container(
      color: _purple,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _statCard('Total', '${semua.length}', Icons.folder_rounded, Colors.white),
          const SizedBox(width: 8),
          _statCard('Menunggu', '$menunggu', Icons.hourglass_empty_rounded, const Color(0xFFfde68a)),
          const SizedBox(width: 8),
          _statCard('Disetujui', '$disetujui', Icons.check_circle_rounded, const Color(0xFF86efac)),
          const SizedBox(width: 8),
          _statCard('Ditolak', '$ditolak', Icons.cancel_rounded, const Color(0xFFfca5a5)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: _purple,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        tabs: const [
          Tab(text: '⏳ Perlu Ditindak'),
          Tab(text: '✅ Disetujui'),
          Tab(text: '📋 Semua'),
        ],
      ),
    );
  }

  // ── LIST ───────────────────────────────────────────────

  Widget _buildList(
    List<PengajuanSurat> list, {
    required bool showActions,
    bool showStatusBadge = false,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFf3e8ff),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text('🎉', style: TextStyle(fontSize: 38))),
            ),
            const SizedBox(height: 16),
            const Text('Tidak ada pengajuan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: Color(0xFF64748b))),
            if (showActions) ...[
              const SizedBox(height: 6),
              const Text('Semua pengajuan telah ditindaklanjuti',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(
        list[i],
        showActions: showActions,
        showStatusBadge: showStatusBadge,
      ),
    );
  }

  // ── KARTU ADMIN ────────────────────────────────────────

  Widget _buildCard(
    PengajuanSurat p, {
    required bool showActions,
    required bool showStatusBadge,
  }) {
    final (Color statusColor, Color statusBg, IconData statusIcon) =
        switch (p.status) {
      StatusPengajuan.menunggu  => (_amber, const Color(0xFFfef3c7), Icons.hourglass_empty_rounded),
      StatusPengajuan.disetujui => (_green, const Color(0xFFdcfce7), Icons.check_circle_rounded),
      StatusPengajuan.ditolak   => (_red,   const Color(0xFFfee2e2), Icons.cancel_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
        border: showActions
            ? Border.all(color: const Color(0xFFfcd34d).withOpacity(0.5))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header kartu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf3e8ff),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.jenisSurat,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1e293b))),
                      const SizedBox(height: 2),
                      Text(p.id,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94a3b8))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: Color(0xFF94a3b8)),
                          const SizedBox(width: 3),
                          Text(
                            _fmtTgl(p.tanggalAjuan),
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF94a3b8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showStatusBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 3),
                        Text(p.statusLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Preview data form (3 field pertama)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFe2e8f0)),
              ),
              child: Column(
                children: p.data.entries.take(4).map((e) {
                  const labels = {
                    'nama': 'Nama', 'nik': 'NIK', 'ttl': 'Tgl. Lahir',
                    'alamat': 'Alamat', 'nama_almarhum': 'Nama',
                    'nama_anak': 'Nama Anak', 'nama_usaha': 'Nama Usaha',
                  };
                  final label = labels[e.key] ?? e.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748b))),
                        ),
                        const Text(': ',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748b))),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Tombol lihat detail
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showDetailModal(p),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lihat semua data →',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7c3aed),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Alasan tolak
            if (p.status == StatusPengajuan.ditolak && p.alasanTolak != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFfef2f2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFfca5a5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: _red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alasan penolakan: ${p.alasanTolak}',
                        style: const TextStyle(
                            fontSize: 11, color: _red, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Tombol aksi (hanya untuk tab Menunggu)
            if (showActions && p.status == StatusPengajuan.menunggu) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFf1f5f9)),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Tombol Tolak
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _dialogTolak(p),
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: const Text('Tolak',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tombol Setujui
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _dialogApprove(p),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Setujui & Buat Surat',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── DIALOG APPROVE ─────────────────────────────────────

  void _dialogApprove(PengajuanSurat p) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFdcfce7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 16),
              const Text(
                'Setujui Pengajuan?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const SizedBox(height: 10),
              Text(
                'Pengajuan "${p.jenisSurat}" akan disetujui. '
                'Surat akan otomatis dibuat dan warga dapat langsung mengunduh PDF-nya.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF475569), height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748b),
                        side: const BorderSide(color: Color(0xFFe2e8f0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _service.approvePengajuan(p.id);
                        Navigator.pop(context);
                        _snackbar(
                          '✅ Surat disetujui — warga dapat mengunduh PDF',
                          _green,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('Ya, Setujui',
                          style: TextStyle(fontWeight: FontWeight.w800)),
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

  // ── DIALOG TOLAK ───────────────────────────────────────

  void _dialogTolak(PengajuanSurat p) {
    final alasanCtrl = TextEditingController();
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFfee2e2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Icon(Icons.close_rounded, color: _red, size: 22)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tolak Pengajuan',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pengajuan: ${p.jenisSurat}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Alasan Penolakan *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: alasanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Contoh: Data NIK tidak sesuai, dokumen pendukung tidak lengkap...',
                    hintStyle: const TextStyle(
                        color: Color(0xFFcbd5e1), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFf8fafc),
                    contentPadding: const EdgeInsets.all(12),
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
                      borderSide: const BorderSide(color: _red),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _red),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748b),
                          side: const BorderSide(color: Color(0xFFe2e8f0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batal',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          _service.tolakPengajuan(p.id, alasanCtrl.text.trim());
                          Navigator.pop(context);
                          _snackbar('❌ Pengajuan ditolak', _red);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Tolak',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── MODAL DETAIL DATA LENGKAP ──────────────────────────

  void _showDetailModal(PengajuanSurat p) {
    const labelMap = {
      'nik': 'NIK', 'nama': 'Nama Lengkap', 'ttl': 'Tempat/Tgl. Lahir',
      'jk': 'Jenis Kelamin', 'alamat': 'Alamat', 'keperluan': 'Keperluan',
      'nama_usaha': 'Nama Usaha', 'jenis_usaha': 'Jenis Usaha',
      'alamat_usaha': 'Alamat Usaha', 'sejak': 'Berdiri Sejak',
      'pekerjaan': 'Pekerjaan', 'penghasilan': 'Penghasilan/Bln',
      'agama': 'Agama', 'status': 'Status Perkawinan',
      'nama_pasangan': 'Nama Pasangan', 'nama_anak': 'Nama Anak',
      'jk_anak': 'JK Anak', 'tgl_lahir': 'Tanggal Lahir',
      'tempat_lahir': 'Tempat Lahir', 'nama_ayah': 'Nama Ayah',
      'nama_ibu': 'Nama Ibu', 'nama_almarhum': 'Nama Almarhum',
      'tgl_meninggal': 'Tanggal Meninggal', 'tempat_meninggal': 'Tempat Meninggal',
      'penyebab': 'Penyebab', 'pelapor': 'Nama Pelapor', 'hubungan': 'Hubungan',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFcbd5e1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Judul
              Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.jenisSurat,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(p.id,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
              const SizedBox(height: 16),
              // Data lengkap
              ...p.data.entries.map((e) {
                final label = labelMap[e.key] ?? e.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748b))),
                      ),
                      const Text(': '),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              // Tombol aksi jika masih menunggu
              if (p.status == StatusPengajuan.menunggu)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _dialogTolak(p);
                        },
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _red,
                          side: const BorderSide(color: _red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _dialogApprove(p);
                        },
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Setujui',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
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

  // ── HELPERS ────────────────────────────────────────────

  void _snackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  String _fmtTgl(DateTime dt) {
    const bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bln[dt.month]} ${dt.year}';
  }
}