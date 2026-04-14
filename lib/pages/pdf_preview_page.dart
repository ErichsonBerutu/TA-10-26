import 'package:flutter/material.dart';
import '../models/pengajuan_model.dart';

// ============================================================
//  HALAMAN PDF PREVIEW & DOWNLOAD
//  Menampilkan preview surat yang sudah disetujui
// ============================================================

class PdfPreviewPage extends StatelessWidget {
  final PengajuanSurat pengajuan;

  const PdfPreviewPage({super.key, required this.pengajuan});

  String _formatTanggal(DateTime dt) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(height: 16),
                    _buildSuratPreview(context),
                    const SizedBox(height: 20),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16a34a), Color(0xFF15803d)],
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x4016a34a),
              blurRadius: 12,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.picture_as_pdf_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Surat Resmi Desa',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Badge ─────────────────────────────────────────

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFdcfce7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF16a34a).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('✅', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Disetujui',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803d),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Surat Anda telah ditandatangani secara digital oleh Kepala Desa',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview Surat ────────────────────────────────────────

  Widget _buildSuratPreview(BuildContext context) {
    final tglRespons = pengajuan.tanggalRespons != null
        ? _formatTanggal(pengajuan.tanggalRespons!)
        : '-';
    final nama = pengajuan.data['nama'] ?? pengajuan.data['nama_anak'] ?? '-';
    final nik = pengajuan.data['nik'] ?? '-';
    final alamat = pengajuan.data['alamat'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kop Surat
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1e3a8a), Color(0xFF2563eb)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                const Text(
                  'PEMERINTAH DESA HUTABULU MEJAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Kecamatan ..., Kabupaten ...',
                  style: TextStyle(
                    color: Color(0xFFbfdbfe),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  pengajuan.jenisSurat.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'No: ${pengajuan.id} / ${DateTime.now().year}',
                  style: const TextStyle(
                    color: Color(0xFFbfdbfe),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Isi Surat
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yang bertanda tangan di bawah ini, Kepala Desa Hutabulu Mejan, menerangkan bahwa:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Data pemohon
                _dataRow('Nama', nama),
                _dataRow('NIK', nik),
                _dataRow('Alamat', alamat),
                ...pengajuan.data.entries
                    .where((e) =>
                        e.key != 'nama' &&
                        e.key != 'nik' &&
                        e.key != 'alamat')
                    .map((e) => _dataRow(
                          _labelFromKey(e.key),
                          e.value,
                        )),

                const SizedBox(height: 16),
                Text(
                  'Demikian surat keterangan ini dibuat untuk digunakan sebagaimana mestinya.',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Tanda tangan
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Hutabulu Mejan, $tglRespons',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kepala Desa,',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Container(
                          height: 1,
                          width: 120,
                          color: const Color(0xFF374151),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '( ................................ )',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // Stempel digital
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff6ff),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF2563eb).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF2563eb), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dokumen ini telah diverifikasi secara digital pada $tglRespons',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2563eb),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6b7280),
              ),
            ),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFromKey(String key) {
    const labels = {
      'ttl': 'Tempat/Tgl Lahir',
      'jk': 'Jenis Kelamin',
      'keperluan': 'Keperluan',
      'nama_usaha': 'Nama Usaha',
      'jenis_usaha': 'Jenis Usaha',
      'alamat_usaha': 'Alamat Usaha',
      'sejak': 'Berdiri Sejak',
      'pekerjaan': 'Pekerjaan',
      'penghasilan': 'Penghasilan',
      'agama': 'Agama',
      'status': 'Status',
      'nama_pasangan': 'Nama Pasangan',
      'nama_anak': 'Nama Anak',
      'jk_anak': 'Jenis Kelamin',
      'tgl_lahir': 'Tanggal Lahir',
      'tempat_lahir': 'Tempat Lahir',
      'nama_ayah': 'Nama Ayah',
      'nama_ibu': 'Nama Ibu',
      'nama_almarhum': 'Nama Almarhum',
      'tgl_meninggal': 'Tanggal Meninggal',
      'tempat_meninggal': 'Tempat Meninggal',
      'penyebab': 'Penyebab',
      'pelapor': 'Nama Pelapor',
      'hubungan': 'Hubungan',
    };
    return labels[key] ?? key;
  }

  // ── Action Buttons ───────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Tombol Print/Simpan PDF
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDownloadInfo(context),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text(
              'Simpan / Cetak PDF',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16a34a),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Tombol Kembali
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748b),
              side: const BorderSide(color: Color(0xFFe2e8f0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Kembali',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showDownloadInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🖨️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Cetak / Simpan Surat',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1e293b)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Untuk menyimpan atau mencetak surat ini, integrasikan package "printing" dan "pdf" dari pub.dev ke project Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                    height: 1.5),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFe2e8f0)),
                ),
                child: const Text(
                  'dependencies:\n  pdf: ^3.10.8\n  printing: ^5.12.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Mengerti',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}