import 'package:flutter/material.dart';
import '../models/pengaduan_model.dart';
import '../services/respons_service.dart';
import '../models/respons_model.dart';
import '../services/auth_service.dart';
import '../api_config/api_config.dart';

class PengaduanDetailPage extends StatefulWidget {
  final PengaduanItem pengaduan;
  const PengaduanDetailPage({super.key, required this.pengaduan});

  @override
  State<PengaduanDetailPage> createState() => _PengaduanDetailPageState();
}

class _PengaduanDetailPageState extends State<PengaduanDetailPage> {
  final _respSvc = ResponsService();
  List<ResponsAdmin> _respons = [];
  bool _loading = true;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRespons();
  }

  Future<void> _loadRespons() async {
    setState(() => _loading = true);
    try {
      final items = await _respSvc.muatRespons(
        idPengajuan: widget.pengaduan.id,
        tipe: TipeRespons.pengaduan,
      );
      setState(() => _respons = items);
    } catch (e) {
      debugPrint('ERROR load respons: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _kirimRespons() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ok = await _respSvc.kirimRespons(
      idPengajuan: widget.pengaduan.id,
      tipe: TipeRespons.pengaduan,
      pesan: text,
    );
    if (ok) {
      _controller.clear();
      await _loadRespons();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Respons terkirim')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim respons')));
    }
  }

  String _resolveFotoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final baseDomain = ApiConfig.baseUrl.replaceAll('/api', '');
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseDomain/$cleanPath';
  }

  String _formatTgl(DateTime dt) {
    const bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bln[dt.month]} ${dt.year}';
  }

  Color _getStatusColor(StatusPengaduan status) {
    switch (status) {
      case StatusPengaduan.menunggu:
        return const Color(0xFFb45309);
      case StatusPengaduan.diproses:
        return const Color(0xFFb45309);
      case StatusPengaduan.selesai:
        return const Color(0xFF16a34a);
      case StatusPengaduan.ditolak:
        return const Color(0xFFdc2626);
    }
  }

  Color _getStatusBg(StatusPengaduan status) {
    switch (status) {
      case StatusPengaduan.menunggu:
        return const Color(0xFFfef3c7);
      case StatusPengaduan.diproses:
        return const Color(0xFFfef3c7);
      case StatusPengaduan.selesai:
        return const Color(0xFFf0fdf4);
      case StatusPengaduan.ditolak:
        return const Color(0xFFfef2f2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pengaduan;
    final fotoUrl = _resolveFotoUrl(p.fotoPath);
    final isAdmin = AuthService().currentUser?.role == 'admin';
    final statusColor = _getStatusColor(p.status);
    final statusBg = _getStatusBg(p.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengaduan'),
        backgroundColor: const Color(0xFF2563eb),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status Banner ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: statusBg,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${p.statusLabel}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTgl(p.tanggalAjuan),
                      style: const TextStyle(
                        color: Color(0xFF64748b),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main Content ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan emoji
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFf1f5f9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(p.jenisEmoji, style: const TextStyle(fontSize: 28))),
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
                                  fontSize: 16,
                                  color: Color(0xFF0f172a),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf1f5f9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.jenisLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Info Pengaduan
                    const Text(
                      'Isi Pengaduan',
                      style: TextStyle(
                        color: Color(0xFF64748b),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFe2e8f0)),
                      ),
                      child: Text(
                        p.deskripsi,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),

                    // Foto Bukti
                    if (fotoUrl.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Foto Bukti',
                        style: TextStyle(
                          color: Color(0xFF64748b),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          height: 240,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFf1f5f9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: Color(0xFF94a3b8), size: 40),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Tanggapan Admin Section
                    const Text(
                      'Tanggapan Admin / Perangkat Desa',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_respons.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf8fafc),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFe2e8f0)),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada tanggapan dari admin.',
                            style: TextStyle(
                              color: Color(0xFF64748b),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _respons.map((r) => _buildResponsCard(r)).toList(),
                      ),

                    // Form Input Tanggapan untuk Admin
                    if (isAdmin) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFeff6ff),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFbfdbfe)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFF2563eb)),
                                SizedBox(width: 8),
                                Text(
                                  'Kirim Tanggapan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF1e40af),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _controller,
                              minLines: 3,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: 'Tulis tanggapan atau penjelasan untuk pelapor...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF2563eb), width: 2),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _kirimRespons,
                                    icon: const Icon(Icons.send_rounded, size: 16),
                                    label: const Text(
                                      'Kirim Tanggapan',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563eb),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsCard(ResponsAdmin r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              Expanded(child: Text(r.adminNama, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('${r.tanggalRespons.day} ${r.tanggalRespons.month}/${r.tanggalRespons.year}', style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.pesan, style: const TextStyle(color: Color(0xFF475569), height: 1.4)),
        ],
      ),
    );
  }
}
