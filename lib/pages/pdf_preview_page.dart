import 'package:flutter/material.dart';
import '../models/pengajuan_model.dart';
import '../services/pdf_service.dart';


// ============================================================
//  HALAMAN PDF PREVIEW & DOWNLOAD
//  Menampilkan preview surat yang sudah disetujui
// ============================================================

class PdfPreviewPage extends StatefulWidget {
  final PengajuanSurat pengajuan;

  const PdfPreviewPage({super.key, required this.pengajuan});

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _isDownloading = false;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal Divider di tengah
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTanggal(widget.pengajuan.tanggalRespons ?? widget.pengajuan.tanggalAjuan),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Row Pesan Chat
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Pengirim (Admin)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16a34a).withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Bubble Pesan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nama Pengirim
                              Row(
                                children: [
                                  const Text(
                                    'Admin Layanan Surat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16a34a).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF16a34a),
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Gelembung chat
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo! Surat pengajuan "${widget.pengajuan.jenisSurat}" Anda telah selesai diproses oleh perangkat desa.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1e293b),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Hasil scan/dokumen resmi telah diunggah dan dapat Anda simpan:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748b),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    
                                    // Attachment File Box
                                    _buildFileAttachmentCard(context),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            _buildBottomBar(context),
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
          const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Pesan Resmi Desa',
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

  // ── Attachment File Card ─────────────────────────────────

  Widget _buildFileAttachmentCard(BuildContext context) {
    final filePdfPath = widget.pengajuan.filePdf ?? '';
    final filename = filePdfPath.isNotEmpty ? filePdfPath.split('/').last : 'Surat_Resmi_Desa.pdf';
    final ext = filename.contains('.') ? filename.split('.').last.toUpperCase() : 'PDF';
    
    IconData iconData = Icons.insert_drive_file_rounded;
    Color iconColor = const Color(0xFF2563eb);
    Color bgColor = const Color(0xFFeff6ff);
    
    if (ext == 'PDF') {
      iconData = Icons.picture_as_pdf_rounded;
      iconColor = const Color(0xFFdc2626);
      bgColor = const Color(0xFFfef2f2);
    } else if (['JPG', 'JPEG', 'PNG', 'WEBP'].contains(ext)) {
      iconData = Icons.image_rounded;
      iconColor = const Color(0xFF0284c7);
      bgColor = const Color(0xFFf0f9ff);
    }

    return Container(
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
              // Icon file
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Filename & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1e293b),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '$ext • Selesai disetujui',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF16a34a),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tombol Download
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading
                  ? null
                  : () async {
                      if (widget.pengajuan.status != StatusPengajuan.disetujui) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Surat belum disetujui untuk dicetak')),
                        );
                        return;
                      }

                      setState(() => _isDownloading = true);

                      try {
                        final nomorSurat = widget.pengajuan.nomorSurat ?? widget.pengajuan.id;
                        final originalExt = filePdfPath.isNotEmpty ? filePdfPath.split('.').last : 'pdf';
                        final filenameSave = '${DateTime.now().year.toString()}${DateTime.now().month.toString().padLeft(2,'0')}${DateTime.now().day.toString().padLeft(2,'0')}_${nomorSurat.replaceAll('/', '-')}.$originalExt';

                        await PdfService().downloadOfficialPdfFromServer(
                          context,
                          widget.pengajuan.id,
                          filenameSave,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengunduh file: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isDownloading = false);
                      }
                    },
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 16),
              label: Text(
                _isDownloading ? 'Mengunduh...' : 'Unduh Surat',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text(
            'Kembali',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF475569),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}