// lib/services/pdf_service.dart
//
// Service untuk generate PDF surat resmi desa.
// Menggunakan package: pdf & printing
//
// Tambahkan ke pubspec.yaml:
//   pdf: ^3.10.8
//   printing: ^5.12.0

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext, debugPrint, ScaffoldMessenger, Colors, SnackBar, Text, Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api_config/api_config.dart';
import './auth_service.dart';
import '../models/pengajuan_model.dart';
import '../utils/file_saver_helper.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();


  // ── Label map (key form → label tampil di surat) ───────
  static const _labelMap = {
    'nik'             : 'NIK',
    'nama'            : 'Nama',
    'nama_lengkap'    : 'Nama',
    'ttl'             : 'Tempat/Tgl. Lahir',
    'tempat_tanggal_lahir': 'Tempat/Tgl. Lahir',
    'jk'              : 'Jenis Kelamin',
    'jenis_kelamin'   : 'Jenis Kelamin',
    'alamat'          : 'Alamat',
    'keperluan'       : 'Keperluan',
    'nama_usaha'      : 'Nama Usaha',
    'jenis_usaha'     : 'Jenis Usaha',
    'alamat_usaha'    : 'Alamat Usaha',
    'sejak'           : 'Berdiri Sejak',
    'pekerjaan'       : 'Pekerjaan',
    'penghasilan'     : 'Penghasilan / Bulan',
    'agama'           : 'Agama',
    'status'          : 'Status Perkawinan',
    'nama_pasangan'   : 'Nama Calon Pasangan',
    'nama_anak'       : 'Nama Anak',
    'jk_anak'         : 'Jenis Kelamin Anak',
    'tgl_lahir'       : 'Tanggal Lahir',
    'tempat_lahir'    : 'Tempat Lahir',
    'nama_ayah'       : 'Nama Ayah',
    'nama_ibu'        : 'Nama Ibu',
    'nama_almarhum'   : 'Nama Almarhum',
    'tgl_meninggal'   : 'Tanggal Meninggal',
    'tempat_meninggal': 'Tempat Meninggal',
    'penyebab'        : 'Penyebab Kematian',
    'pelapor'         : 'Nama Pelapor',
    'hubungan'        : 'Hubungan dg Almarhum',
    'nomor_kk'        : 'No. KK',
    'no_kk'           : 'No. KK',
  };

  // ── Normalisasi & Pengurutan Data ────────────────────────
  Map<String, String> _normalizeData(Map<String, String> data) {
    final normalized = <String, String>{};
    
    data.forEach((k, v) {
      normalized[k.toLowerCase()] = v;
    });

    // Combine tempat_lahir and tgl_lahir / tanggal_lahir if both exist
    String? tl = normalized['tempat_lahir'] ?? normalized['tempat'];
    String? tgl = normalized['tgl_lahir'] ?? normalized['tgl'] ?? normalized['tanggal_lahir'];
    
    if (tl != null || tgl != null) {
      final tlStr = tl ?? '-';
      final tglStr = tgl ?? '-';
      normalized['ttl'] = '$tlStr, $tglStr';
      
      normalized.remove('tempat_lahir');
      normalized.remove('tempat');
      normalized.remove('tgl_lahir');
      normalized.remove('tgl');
      normalized.remove('tanggal_lahir');
    }

    if (normalized.containsKey('nama_lengkap') && normalized.containsKey('nama')) {
      normalized.remove('nama_lengkap');
    }
    if (normalized.containsKey('no_kk') && normalized.containsKey('nomor_kk')) {
      normalized.remove('nomor_kk');
    }

    return normalized;
  }

  List<MapEntry<String, String>> _getSortedData(Map<String, String> data) {
    final normalized = _normalizeData(data);
    final keys = normalized.keys.toList();
    const order = [
      'nama',
      'nama_lengkap',
      'nomor_kk',
      'no_kk',
      'nik',
      'ttl',
      'tempat_tanggal_lahir',
      'jk',
      'jenis_kelamin',
      'pekerjaan',
      'alamat',
    ];
    
    keys.sort((a, b) {
      final ia = order.indexOf(a.toLowerCase());
      final ib = order.indexOf(b.toLowerCase());
      if (ia != -1 && ib != -1) return ia.compareTo(ib);
      if (ia != -1) return -1;
      if (ib != -1) return 1;
      return a.compareTo(b);
    });

    return keys.map((k) => MapEntry(k, normalized[k]!)).toList();
  }

  String _getAbbreviation(String jenisSurat) {
    final lower = jenisSurat.toLowerCase();
    if (lower.contains('domisili')) return 'SKD';
    if (lower.contains('usaha')) return 'SKU';
    if (lower.contains('tidak mampu')) return 'SKTM';
    if (lower.contains('nikah') || lower.contains('pengantar')) return 'SPN';
    if (lower.contains('lahir')) return 'SKKL';
    if (lower.contains('kematian')) return 'SKKM';
    return 'SURAT';
  }

  // ── Format tanggal Indonesia ───────────────────────────
  String _fmt(DateTime dt) {
    const bln = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${dt.day} ${bln[dt.month]} ${dt.year}';
  }

  // ── Generate Uint8List PDF ─────────────────────────────
  Future<Uint8List> generatePdf(PengajuanSurat pengajuan) async {
    final doc = pw.Document(
      title   : pengajuan.jenisSurat,
      author  : 'Pemerintah Desa Hutabulu Mejan',
      creator : 'Sistem Administrasi Kependudukan',
    );

    // Load Google Fonts
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();

    final tglSurat = _fmt(pengajuan.tanggalRespons ?? DateTime.now());

    // Load Logo Image Asset
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint("Gagal memuat logo: $e");
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(60, 50, 60, 50),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildKopSurat(logoImage, fontRegular, fontBold),
            pw.SizedBox(height: 10),
            // Garis ganda kop surat
            pw.Container(height: 2.2, color: PdfColors.black),
            pw.SizedBox(height: 1.5),
            pw.Container(height: 0.8, color: PdfColors.black),
            pw.SizedBox(height: 22),
            _buildJudulSurat(pengajuan, fontBold),
            pw.SizedBox(height: 22),
            _buildPembukaan(fontRegular),
            pw.SizedBox(height: 14),
            _buildDataRows(pengajuan, fontRegular, fontBold),
            pw.SizedBox(height: 16),
            _buildPenutup(pengajuan, fontRegular),
            pw.SizedBox(height: 36),
            _buildTandaTangan(tglSurat, fontRegular, fontBold),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── KOP SURAT ──────────────────────────────────────────
  pw.Widget _buildKopSurat(pw.MemoryImage? logoImage, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoImage != null)
          pw.Image(logoImage, width: 65, height: 65)
        else
          pw.Container(width: 65, height: 65),
        pw.SizedBox(width: 15),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'PEMERINTAH KABUPATEN TOBA',
                style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
              ),
              pw.Text(
                'KECAMATAN BALIGE',
                style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
              ),
              pw.Text(
                'DESA HUTABULU MEJAN',
                style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black, letterSpacing: 0.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Jl. Hutabulu Mejan, Kode Pos : 22312, Website : www.hutabulumejan.desa.id',
                style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.black),
              ),
              pw.Text(
                'www.desahutabulumejan.id',
                style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── JUDUL & NOMOR SURAT ────────────────────────────────
  pw.Widget _buildJudulSurat(PengajuanSurat p, pw.Font fontBold) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            p.jenisSurat.toUpperCase(),
            style: pw.TextStyle(
              font       : fontBold,
              fontSize   : 14,
              color      : PdfColors.black,
              decoration : pw.TextDecoration.underline,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Nomor : ${p.nomorSurat ?? '${p.id}/${_getAbbreviation(p.jenisSurat)}/HM/${DateTime.now().year}'}',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  // ── KALIMAT PEMBUKA ────────────────────────────────────
  pw.Widget _buildPembukaan(pw.Font fontRegular) {
    return pw.Text(
      'Yang bertanda tangan dibawah ini, Kepala Desa Hutabulu Mejan, '
      'KECAMATAN BALIGE, KABUPATEN TOBA menerangkan bahwa :',
      style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 4),
      textAlign: pw.TextAlign.justify,
    );
  }

  // ── TABEL DATA DARI FORM ───────────────────────────────
  pw.Widget _buildDataRows(
    PengajuanSurat p,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    final sortedEntries = _getSortedData(p.data);
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 20, right: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: sortedEntries.map((e) {
          final label = _labelMap[e.key] ?? e.key;
          final value = e.value.toUpperCase();
          final isNameField = e.key.toLowerCase().contains('nama');
          final valueFont = isNameField ? fontBold : fontRegular;

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black),
                  ),
                ),
                pw.Text(
                  ': ',
                  style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black),
                ),
                pw.Expanded(
                  child: pw.Text(
                    value,
                    style: pw.TextStyle(font: valueFont, fontSize: 11, color: PdfColors.black),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── KALIMAT PENUTUP (berbeda per jenis surat) ──────────
  pw.Widget _buildPenutup(PengajuanSurat p, pw.Font fontRegular) {
    final jenis = p.jenisSurat.toLowerCase();
    
    if (jenis.contains('tidak mampu')) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Nama tersebut diatas adalah benar Penduduk Desa Hutabulu Mejan dan nama tersebut diatas merupakan keluarga Tidak Mampu.',
            style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 4),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Surat Keterangan Tidak Mampu ini dibuat untuk dipergunakan sebagai keperluan yang dibutuhkan.',
            style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 4),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Demikianlah Surat Keterangan Tidak Mampu ini dibuat agar dapat dipergunakan sebagaimana mestinya.',
            style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 4),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      );
    }

    String penutup;
    if (jenis.contains('domisili')) {
      penutup =
          'Demikian Surat Keterangan Domisili ini kami buat dengan sebenarnya '
          'agar dapat dipergunakan sebagaimana mestinya.';
    } else if (jenis.contains('usaha')) {
      penutup =
          'Demikian Surat Keterangan Usaha ini kami buat dengan sebenarnya '
          'untuk dapat dipergunakan sebagaimana mestinya oleh yang bersangkutan.';
    } else if (jenis.contains('nikah') || jenis.contains('pengantar')) {
      penutup =
          'Demikian Surat Pengantar Nikah ini kami buat untuk dapat dipergunakan '
          'sebagaimana mestinya oleh yang bersangkutan dalam proses pernikahan.';
    } else if (jenis.contains('kelahiran')) {
      penutup =
          'Demikian Surat Keterangan Kelahiran ini kami buat dengan sebenarnya '
          'berdasarkan data dan laporan yang diterima, untuk dapat dipergunakan '
          'sebagaimana mestinya.';
    } else if (jenis.contains('kematian')) {
      penutup =
          'Demikian Surat Keterangan Kematian ini kami buat berdasarkan laporan '
          'yang telah diterima dan dapat dipergunakan sebagaimana mestinya '
          'dalam pengurusan administrasi yang diperlukan.';
    } else {
      penutup =
          'Demikian surat keterangan ini kami buat dengan sebenarnya '
          'untuk dapat dipergunakan sebagaimana mestinya.';
    }

    return pw.Text(
      penutup,
      style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 4),
      textAlign: pw.TextAlign.justify,
    );
  }

  // ── TANDA TANGAN ───────────────────────────────────────
  pw.Widget _buildTandaTangan(String tglSurat, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.SizedBox(width: 90, child: pw.Text('Dikeluarkan di', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black))),
                pw.Text(': Desa Hutabulu Mejan', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black)),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.SizedBox(width: 90, child: pw.Text('Pada Tanggal', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black))),
                pw.Text(': $tglSurat', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Kepala Desa Hutabulu Mejan',
                    style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 65),
                  pw.Text(
                    'KEPALA DESA HUTABULU MEJAN',
                    style: pw.TextStyle(
                      font      : fontBold,
                      fontSize  : 11,
                      color     : PdfColors.black,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── TRIGGER PRINT / SAVE DIALOG ───────────────────────
  Future<void> downloadSurat(
    BuildContext context,
    PengajuanSurat pengajuan,
  ) async {
    final bytes = await generatePdf(pengajuan);
    await Printing.layoutPdf(
      onLayout : (_) async => bytes,
      name     : '${pengajuan.jenisSurat} - ${pengajuan.id}',
      format   : PdfPageFormat.a4,
    );
  }

  // ── DOWNLOAD OFFICIAL SIGNED PDF FROM SERVER ─────────
  Future<void> downloadOfficialPdfFromServer(
    BuildContext context,
    String pengajuanId,
    String filename,
  ) async {
    final token = AuthService().token;
    if (token == null) {
      debugPrint("downloadOfficialPdfFromServer: token is null");
      return;
    }

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/surat/$pengajuanId/download");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Deteksi nama file asli dari header Content-Disposition
        String actualFilename = filename;
        String? contentDisposition;
        response.headers.forEach((key, val) {
          if (key.toLowerCase() == 'content-disposition') {
            contentDisposition = val;
          }
        });

        if (contentDisposition != null) {
          final regExp = RegExp(r'filename="?([^";\n]+)"?');
          final match = regExp.firstMatch(contentDisposition!);
          if (match != null && match.groupCount >= 1) {
            actualFilename = match.group(1)!.replaceAll('"', '').trim();
          }
        }

        // Deteksi tipe file dari ekstensi
        final ext = actualFilename.split('.').last.toLowerCase();
        final List<String> allowedExtensions = [ext];
        if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
          allowedExtensions.addAll(['jpg', 'jpeg', 'png']);
        } else if (ext == 'pdf') {
          allowedExtensions.add('pdf');
        } else {
          allowedExtensions.add(ext);
        }
        
        if (kIsWeb) {
          await saveFileWeb(bytes, actualFilename);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Surat berhasil diunduh!'),
                backgroundColor: Color(0xFF16a34a),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Pilih lokasi untuk menyimpan surat',
          fileName: actualFilename,
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
          bytes: bytes,
        );

        if (outputPath != null) {
          try {
            final file = File(outputPath);
            await file.writeAsBytes(bytes);
          } catch (e) {
            debugPrint("Direct file write failed: $e. Handled by file_picker.");
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Surat berhasil diunduh dan disimpan!'),
                backgroundColor: Color(0xFF16a34a),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unduh surat dibatalkan.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        debugPrint("downloadOfficialPdfFromServer error: ${response.statusCode} - ${response.body}");
        throw Exception("Gagal mengunduh file resmi dari server.");
      }
    } catch (e) {
      debugPrint("Exception in downloadOfficialPdfFromServer: $e");
      rethrow;
    }
  }
}