// lib/pages/detail_pengajuan_page.dart

import 'package:flutter/material.dart';
import '../models/pengajuan_model.dart';
import '../models/respons_model.dart';
import '../services/respons_service.dart';

// ============================================================
//  HALAMAN — Detail Pengajuan (Lihat Respons Admin)
// ============================================================

class DetailPengajuanPage extends StatefulWidget {
  final PengajuanSurat pengajuan;

  const DetailPengajuanPage({
    Key? key,
    required this.pengajuan,
  }) : super(key: key);

  @override
  State<DetailPengajuanPage> createState() => _DetailPengajuanPageState();
}

class _DetailPengajuanPageState extends State<DetailPengajuanPage> {
  final _responService = ResponsService();
  List<ResponsAdmin> _respons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRespons();
  }

  Future<void> _loadRespons() async {
    setState(() => _loading = true);
    final respons = await _responService.muatRespons(
      idPengajuan: widget.pengajuan.id,
      tipe: TipeRespons.pengajuan,
    );
    setState(() {
      _respons = respons;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pengajuan ${widget.pengajuan.jenisSurat}'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Card Status ────────────────────────────────

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: _getStatusColor(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.pengajuan.statusEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pengajuan.statusLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.pengajuan.tanggalRespons != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Direspons: ${_formatTanggal(widget.pengajuan.tanggalRespons!)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Informasi Pengajuan ────────────────────────

          Text(
            'Informasi Pengajuan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Jenis Surat', widget.pengajuan.jenisSurat),
                  const Divider(),
                  _buildInfoRow(
                    'Tanggal Ajuan',
                    _formatTanggal(widget.pengajuan.tanggalAjuan),
                  ),
                  const Divider(),
                  Text(
                    'Detail:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.pengajuan.data.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${e.key}:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(e.value),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Pesan Admin (jika ditolak) ─────────────────

          if (widget.pengajuan.status == StatusPengajuan.ditolak &&
              widget.pengajuan.alasanTolak != null) ...[
            Text(
              'Alasan Penolakan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.pengajuan.alasanTolak!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Respons Admin ──────────────────────────────

          Text(
            'Respons Admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_respons.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Belum ada respons dari admin',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            Column(
              children: _respons.map((r) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.adminNama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatTanggal(r.tanggalRespons),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.pesan),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.pengajuan.status) {
      case StatusPengajuan.menunggu:
        return Colors.orange;
      case StatusPengajuan.disetujui:
        return Colors.green;
      case StatusPengajuan.ditolak:
        return Colors.red;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatTanggal(DateTime tanggal) {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year} ${tanggal.hour}:${tanggal.minute.toString().padLeft(2, '0')}';
  }
}
