// lib/pages/detail_pengaduan_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pengaduan_model.dart';
import '../models/respons_model.dart';
import '../services/respons_service.dart';
import '../api_config/api_config.dart';
import '../widgets/custom_cached_image.dart';

// ============================================================
//  HALAMAN — Detail Pengaduan (Lihat Respons Admin)
// ============================================================

class DetailPengaduanPage extends StatefulWidget {
  final PengaduanItem pengaduan;

  const DetailPengaduanPage({
    Key? key,
    required this.pengaduan,
  }) : super(key: key);

  @override
  State<DetailPengaduanPage> createState() => _DetailPengaduanPageState();
}

class _DetailPengaduanPageState extends State<DetailPengaduanPage> {
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
      idPengajuan: widget.pengaduan.id,
      tipe: TipeRespons.pengaduan,
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
        title: const Text('Detail Pengaduan'),
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
                    _getStatusEmoji(),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusLabel(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.pengaduan.tanggalRespons != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Direspons: ${_formatTanggal(widget.pengaduan.tanggalRespons!)}',
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

          // ── Informasi Pengaduan ────────────────────────

          Text(
            'Informasi Pengaduan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pengaduan.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getJenisLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    'Deskripsi:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.pengaduan.deskripsi),
                  const Divider(height: 16),
                  _buildInfoRow(
                    'Tanggal Pengaduan',
                    _formatTanggal(widget.pengaduan.tanggalAjuan),
                  ),
                  if (widget.pengaduan.fotoPath != null && widget.pengaduan.fotoPath!.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(
                      'Lampiran:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildImageWidget(widget.pengaduan.fotoPath!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Catatan Admin (jika ditolak) ───────────────

          if (widget.pengaduan.status == StatusPengaduan.ditolak &&
              widget.pengaduan.catatanAdmin != null) ...[
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
                widget.pengaduan.catatanAdmin!,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.pengaduan.status) {
      case StatusPengaduan.menunggu:
        return Colors.orange;
      case StatusPengaduan.diproses:
        return Colors.orange;
      case StatusPengaduan.selesai:
        return Colors.green;
      case StatusPengaduan.ditolak:
        return Colors.red;
    }
  }

  String _getStatusEmoji() {
    switch (widget.pengaduan.status) {
      case StatusPengaduan.menunggu:
        return '⏳';
      case StatusPengaduan.diproses:
        return '⏳';
      case StatusPengaduan.selesai:
        return '✅';
      case StatusPengaduan.ditolak:
        return '❌';
    }
  }

  String _getStatusLabel() {
    switch (widget.pengaduan.status) {
      case StatusPengaduan.menunggu:
        return 'Menunggu';
      case StatusPengaduan.diproses:
        return 'Menunggu';
      case StatusPengaduan.selesai:
        return 'Berhasil';
      case StatusPengaduan.ditolak:
        return 'Ditolak';
    }
  }

  String _getJenisLabel() {
    switch (widget.pengaduan.jenis) {
      case JenisPengaduan.infrastruktur:
        return 'Infrastruktur';
      case JenisPengaduan.pelayanan:
        return 'Pelayanan';
      case JenisPengaduan.keamanan:
        return 'Keamanan';
      case JenisPengaduan.lingkungan:
        return 'Lingkungan';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
    final hourStr = tanggal.hour.toString().padLeft(2, '0');
    final minuteStr = tanggal.minute.toString().padLeft(2, '0');
    return '${tanggal.day}/${tanggal.month}/${tanggal.year} $hourStr:$minuteStr';
  }
  Widget _buildImageWidget(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CustomCachedImage(
        imageUrl: path,
        fit: BoxFit.cover,
        errorWidget: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.red, size: 40),
        ),
      );
    } else if (path.contains('storage/')) {
      final rootUrl = ApiConfig.baseUrl.replaceAll('/api', '');
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final fullUrl = "$rootUrl/$cleanPath";
      return CustomCachedImage(
        imageUrl: fullUrl,
        fit: BoxFit.cover,
        errorWidget: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.red, size: 40),
        ),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.red, size: 40),
        ),
      );
    }
  }
}
