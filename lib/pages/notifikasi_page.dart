// lib/pages/notifikasi_page.dart

import 'package:flutter/material.dart';
import '../services/notifikasi_service.dart';

// ============================================================
//  HALAMAN — Notifikasi (sync dari server backend)
// ============================================================

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final _svc = NotifikasiService();
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool force = false}) async {
    setState(() => _refreshing = true);
    await _svc.loadNotifikasi(forceRefresh: force);
    if (mounted) setState(() => _refreshing = false);
  }

  // ── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1e40af),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Refresh
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshing ? null : () => _fetch(force: true),
            tooltip: 'Perbarui',
          ),
          // Tandai semua dibaca
          AnimatedBuilder(
            animation: _svc,
            // ignore: avoid_types_on_closure_parameters
            builder: (BuildContext ctx, Widget? child) {
              if (_svc.belumDibaca.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  await _svc.tandaiSemuaDibaca();
                  if (mounted) setState(() {});
                },
                child: const Text(
                  'Tandai Dibaca',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _svc,
        builder: (context, _) {
          if (!_svc.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1e40af)),
            );
          }

          if (_svc.notifikasi.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () => _fetch(force: true),
            color: const Color(0xFF1e40af),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _svc.notifikasi.length,
              itemBuilder: (context, i) => _buildItem(_svc.notifikasi[i]),
            ),
          );
        },
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: () => _fetch(force: true),
      color: const Color(0xFF1e40af),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2e8f0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('🔕', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada notifikasi',
                  style: TextStyle(
                    color: Color(0xFF64748b),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Notifikasi akan muncul setelah\nadmin memproses pengajuan Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94a3b8), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Item Notifikasi ────────────────────────────────────────

  Widget _buildItem(NotifikasiItem notif) {
    final color = _getColor(notif.tipe);

    return InkWell(
      onTap: () async {
        if (!notif.sudahDibaca) {
          await _svc.tandaiDibaca(notif.id);
          if (mounted) setState(() {});
        }
        _showDetail(notif);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: notif.sudahDibaca ? const Color(0xFFf1f5f9) : color.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Center(child: Text(notif.ikon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            // Konten
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.judul,
                          style: TextStyle(
                            fontWeight: notif.sudahDibaca ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 13.5,
                            color: const Color(0xFF1e293b),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notif.sudahDibaca)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.pesan,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatWaktu(notif.waktu),
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
            // Hapus
            GestureDetector(
              onTap: () {
                _svc.hapusNotifikasi(notif.id);
                setState(() {});
              },
              child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Dialog ───────────────────────────────────────────

  void _showDetail(NotifikasiItem notif) {
    final color = _getColor(notif.tipe);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large elegant icon with background circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    notif.ikon,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Centered Title
              Text(
                notif.judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Color(0xFF1e293b),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              // Centered Time
              Text(
                _formatWaktu(notif.waktu),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Subtle Divider
              const Divider(color: Color(0xFFe2e8f0), height: 1),
              const SizedBox(height: 16),
              // Centered message, highly readable
              Text(
                notif.pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF475569),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              // TUTUP button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1e40af),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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

  // ── Helpers ────────────────────────────────────────────────

  Color _getColor(TipeNotifikasi tipe) {
    switch (tipe) {
      case TipeNotifikasi.disetujui:
        return Colors.green;
      case TipeNotifikasi.ditolak:
        return Colors.red;
      case TipeNotifikasi.pengajuanBaru:
        return Colors.blue;
      case TipeNotifikasi.pengaduanBaru:
        return Colors.orange;
      case TipeNotifikasi.pengaduanTerkirim:
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  String _formatWaktu(DateTime waktu) {
    final diff = DateTime.now().difference(waktu);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${waktu.day}/${waktu.month}/${waktu.year}';
  }
}