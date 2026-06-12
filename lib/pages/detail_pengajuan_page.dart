import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import '../models/pengajuan_model.dart';
import '../models/persyaratan_model.dart';
import '../models/respons_model.dart';
import '../services/auth_service.dart';
import '../services/offline_database_service.dart';
import '../services/respons_service.dart';
import 'form_pengajuan_surat_page.dart';

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

  /// Navigasi ke form edit pengajuan
  Future<void> _navigateToEditForm() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = AuthService().token;
      List<PersyaratanSuratModel> persyaratan = [];

      // Ambil dari cache lokal
      final localPersyaratan = await OfflineDatabaseService()
          .ambilPersyaratan(widget.pengajuan.jenisSuratId);

      if (localPersyaratan.isNotEmpty) {
        persyaratan = localPersyaratan
            .map((item) => PersyaratanSuratModel.fromJson(item))
            .toList();
      }

      // Fetch dari API jika cache kosong
      if (persyaratan.isEmpty && token != null) {
        final url = Uri.parse(
            '${ApiConfig.baseUrl}/dynamic/persyaratan/${widget.pengajuan.jenisSuratId}');
        final response = await http.get(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body['status'] == true && body['data'] != null) {
            final List rawList = body['data'];
            persyaratan = rawList
                .map((item) => PersyaratanSuratModel.fromJson(item))
                .toList();
            final List<Map<String, dynamic>> cacheList = rawList
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            await OfflineDatabaseService()
                .simpanPersyaratan(widget.pengajuan.jenisSuratId, cacheList);
          }
        }
      }

      if (mounted) Navigator.pop(context); // Tutup loading dialog

      if (persyaratan.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat formulir persyaratan. Periksa koneksi Anda.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormPengajuanSuratPage(
              jenisSuratId: widget.pengajuan.jenisSuratId,
              namaSurat: widget.pengajuan.jenisSurat,
              editPengajuanId: widget.pengajuan.id,
              existingData: widget.pengajuan.data,
            ),
          ),
        );
        // Setelah kembali dari form edit, kembali ke halaman sebelumnya agar data terefresh
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

          _buildTimelineTracker(),
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
          if (widget.pengajuan.status == StatusPengajuan.menunggu) ...[
            const SizedBox(height: 16),
            // ── Tombol Edit Pengajuan ──────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563eb), Color(0xFF1e40af)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563eb).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToEditForm(),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text(
                  'Edit Pengajuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Anda masih dapat mengubah data pengajuan selama belum diproses admin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (widget.pengajuan.status == StatusPengajuan.ditolak) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final token = AuthService().token;
                  List<PersyaratanSuratModel> persyaratan = [];
                  
                  final localPersyaratan = await OfflineDatabaseService()
                      .ambilPersyaratan(widget.pengajuan.jenisSuratId);
                  
                  if (localPersyaratan.isNotEmpty) {
                    persyaratan = localPersyaratan
                        .map((item) => PersyaratanSuratModel.fromJson(item))
                        .toList();
                  }
                  
                  if (persyaratan.isEmpty && token != null) {
                    final url = Uri.parse(
                        '${ApiConfig.baseUrl}/dynamic/persyaratan/${widget.pengajuan.jenisSuratId}');
                    final response = await http.get(
                      url,
                      headers: {
                        'Accept': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                    ).timeout(const Duration(seconds: 10));

                    if (response.statusCode == 200) {
                      final body = jsonDecode(response.body);
                      if (body['status'] == true && body['data'] != null) {
                        final List rawList = body['data'];
                        persyaratan = rawList
                            .map((item) => PersyaratanSuratModel.fromJson(item))
                            .toList();
                        final List<Map<String, dynamic>> cacheList = rawList
                            .map((item) => Map<String, dynamic>.from(item))
                            .toList();
                        await OfflineDatabaseService()
                            .simpanPersyaratan(widget.pengajuan.jenisSuratId, cacheList);
                      }
                    }
                  }

                  if (mounted) Navigator.pop(context);

                  if (persyaratan.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal memuat formulir persyaratan. Periksa koneksi Anda.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  final Map<String, String> draftMap = {};
                  for (final req in persyaratan) {
                    final matchKey = widget.pengajuan.data.keys.firstWhere(
                      (k) => k.trim().toLowerCase() == req.namaField.trim().toLowerCase(),
                      orElse: () => '',
                    );
                    if (matchKey.isNotEmpty) {
                      final val = widget.pengajuan.data[matchKey]!;
                      if (!val.startsWith('[Unggahan Foto]') && !val.startsWith('[FILE_PATH]')) {
                        draftMap[req.id.toString()] = val;
                      }
                    }
                  }

                  await OfflineDatabaseService()
                      .simpanDraftPengajuan(widget.pengajuan.jenisSuratId, draftMap);

                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormPengajuanSuratPage(
                          jenisSuratId: widget.pengajuan.jenisSuratId,
                          namaSurat: widget.pengajuan.jenisSurat,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Terjadi kesalahan: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.edit_note_rounded, size: 24),
              label: const Text(
                'Perbaiki & Ajukan Kembali',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1e40af),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.pengajuan.status) {
      case StatusPengajuan.menunggu:
        return Colors.orange;
      case StatusPengajuan.diproses:
        return Colors.blue;
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

  Widget _buildTimelineTracker() {
    // Tentukan status tiap langkah
    // Langkah 1: Diajukan (Selalu selesai)
    bool step1Done = true;
    DateTime step1Date = widget.pengajuan.tanggalAjuan;

    // Langkah 2: Diproses / Diverifikasi
    bool step2Done = widget.pengajuan.status == StatusPengajuan.diproses ||
                     widget.pengajuan.status == StatusPengajuan.disetujui ||
                     widget.pengajuan.status == StatusPengajuan.ditolak;
    bool step2Active = widget.pengajuan.status == StatusPengajuan.diproses;

    // Langkah 3: Hasil (Disetujui / Ditolak)
    bool step3Done = widget.pengajuan.status == StatusPengajuan.disetujui ||
                     widget.pengajuan.status == StatusPengajuan.ditolak;
    bool isDitolak = widget.pengajuan.status == StatusPengajuan.ditolak;
    bool isDisetujui = widget.pengajuan.status == StatusPengajuan.disetujui;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Alur Pengajuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            // Step 1: Diajukan
            _buildTimelineStep(
              title: 'Pengajuan Dikirim',
              subtitle: 'Formulir pengajuan telah dikirim oleh pemohon',
              date: step1Date,
              isCompleted: step1Done,
              isActive: widget.pengajuan.status == StatusPengajuan.menunggu,
              isLast: false,
            ),
            // Step 2: Diverifikasi
            _buildTimelineStep(
              title: 'Diverifikasi Staf Desa',
              subtitle: step2Done 
                  ? 'Berkas telah diperiksa dan sedang diproses admin' 
                  : 'Menunggu antrean verifikasi berkas persyaratan',
              date: (widget.pengajuan.status == StatusPengajuan.diproses || step3Done) ? widget.pengajuan.tanggalRespons : null,
              isCompleted: step2Done,
              isActive: step2Active,
              isLast: false,
            ),
            // Step 3: Hasil
            _buildTimelineStep(
              title: isDitolak
                  ? 'Pengajuan Ditolak'
                  : (isDisetujui ? 'Disetujui & Selesai' : 'Surat Diterbitkan'),
              subtitle: isDitolak
                  ? 'Pengajuan ditolak oleh admin (lihat alasan di bawah)'
                  : (isDisetujui 
                      ? 'Surat telah ditandatangani dan siap diunduh' 
                      : 'Menunggu keputusan Kepala Desa'),
              date: step3Done ? widget.pengajuan.tanggalRespons : null,
              isCompleted: step3Done,
              isActive: false,
              isError: isDitolak,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    DateTime? date,
    required bool isCompleted,
    required bool isActive,
    bool isError = false,
    required bool isLast,
  }) {
    Color iconBgColor = Colors.grey[200]!;
    Color iconColor = Colors.grey[500]!;
    if (isCompleted) {
      if (isError) {
        iconBgColor = const Color(0xFFFEE2E2); // red[100]
        iconColor = Colors.red;
      } else {
        iconBgColor = const Color(0xFFDCFCE7); // green[100]
        iconColor = Colors.green;
      }
    } else if (isActive) {
      iconBgColor = const Color(0xFFDBEAFE); // blue[100]
      iconColor = Colors.blue;
    }

    IconData stepIcon = Icons.radio_button_unchecked_rounded;
    if (isCompleted) {
      stepIcon = isError ? Icons.cancel_rounded : Icons.check_circle_rounded;
    } else if (isActive) {
      stepIcon = Icons.hourglass_top_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kolom Garis dan Lingkaran
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? Colors.blue : (isCompleted ? (isError ? Colors.red : Colors.green) : Colors.transparent),
                    width: 1.5,
                  ),
                ),
                child: Icon(stepIcon, color: iconColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Kolom Teks Informasi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCompleted 
                              ? (isError ? Colors.red : Colors.green[700]) 
                              : (isActive ? Colors.blue[700] : Colors.black54),
                        ),
                      ),
                      if (date != null)
                        Text(
                          _formatTanggal(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    final hourStr = tanggal.hour.toString().padLeft(2, '0');
    final minuteStr = tanggal.minute.toString().padLeft(2, '0');
    return '${tanggal.day}/${tanggal.month}/${tanggal.year} $hourStr:$minuteStr';
  }
}
