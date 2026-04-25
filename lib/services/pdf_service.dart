// lib/services/pdf_service.dart
//
// Service untuk generate PDF surat resmi desa.
// Menggunakan package: pdf & printing
//
// Tambahkan ke pubspec.yaml:
//   pdf: ^3.10.8
//   printing: ^5.12.0

import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/pengajuan_model.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // ── Warna ──────────────────────────────────────────────
  static final _primaryColor  = PdfColor.fromHex('1e40af');
  static final _textColor     = PdfColor.fromHex('1e293b');
  static final _mutedColor    = PdfColor.fromHex('64748b');
  static final _bgLight       = PdfColor.fromHex('f8fafc');

  // ── Label map (key form → label tampil di surat) ───────
  static const _labelMap = {
    'nik'             : 'NIK',
    'nama'            : 'Nama Lengkap',
    'ttl'             : 'Tempat / Tgl. Lahir',
    'jk'              : 'Jenis Kelamin',
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
  };

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

    // Load Google Fonts (Noto Sans support karakter Indonesia)
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();

    final tglSurat = _fmt(pengajuan.tanggalRespons ?? DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(60, 50, 60, 50),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildKopSurat(fontRegular, fontBold),
            pw.SizedBox(height: 10),
            // Garis ganda kop surat
            pw.Container(height: 2.5, color: _primaryColor),
            pw.SizedBox(height: 2),
            pw.Container(height: 0.8, color: _primaryColor),
            pw.SizedBox(height: 22),
            _buildJudulSurat(pengajuan, fontBold),
            pw.SizedBox(height: 22),
            _buildPembukaan(fontRegular),
            pw.SizedBox(height: 14),
            _buildDataRows(pengajuan, fontRegular, fontBold),
            pw.SizedBox(height: 16),
            _buildPenutup(pengajuan, tglSurat, fontRegular),
            pw.SizedBox(height: 36),
            _buildTandaTangan(tglSurat, fontRegular, fontBold),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── KOP SURAT ──────────────────────────────────────────
  pw.Widget _buildKopSurat(pw.Font fontRegular, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        // Logo placeholder (lingkaran biru)
        pw.Container(
          width: 64, height: 64,
          decoration: pw.BoxDecoration(
            color: _primaryColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              'HM',
              style: pw.TextStyle(
                font     : fontBold,
                fontSize : 18,
                color    : PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 18),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'PEMERINTAH DESA HUTABULU MEJAN',
              style: pw.TextStyle(
                font        : fontBold,
                fontSize    : 14,
                color       : _primaryColor,
                letterSpacing: 0.6,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Kecamatan ..., Kabupaten ..., Provinsi Sumatera Utara',
              style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _mutedColor),
            ),
            pw.Text(
              'Kode Pos: 22xxx   |   Telp: (0xxx) xxxxx   |   Email: desa@hutabulumejan.go.id',
              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: _mutedColor),
            ),
          ],
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
              fontSize   : 13,
              color      : _textColor,
              decoration : pw.TextDecoration.underline,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Nomor : ${p.id} / DESA / ${DateTime.now().year}',
            style: pw.TextStyle(fontSize: 10.5, color: _mutedColor),
          ),
        ],
      ),
    );
  }

  // ── KALIMAT PEMBUKA ────────────────────────────────────
  pw.Widget _buildPembukaan(pw.Font fontRegular) {
    return pw.Text(
      'Yang bertanda tangan di bawah ini, Kepala Desa Hutabulu Mejan, '
      'Kecamatan ..., Kabupaten ..., Provinsi Sumatera Utara, '
      'dengan ini menerangkan dengan sesungguhnya bahwa:',
      style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 3.5),
      textAlign: pw.TextAlign.justify,
    );
  }

  // ── TABEL DATA DARI FORM ───────────────────────────────
  pw.Widget _buildDataRows(
    PengajuanSurat p,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Container(
      margin   : const pw.EdgeInsets.only(left: 20),
      padding  : const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color : _bgLight,
        border: pw.Border.all(color: PdfColor.fromHex('e2e8f0'), width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: p.data.entries.map((e) {
          final label = _labelMap[e.key] ?? e.key;
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 145,
                  child: pw.Text(label,
                      style: pw.TextStyle(font: fontRegular, fontSize: 11, color: _mutedColor)),
                ),
                pw.Text(':  ', style: pw.TextStyle(fontSize: 11, color: _mutedColor)),
                pw.Expanded(
                  child: pw.Text(e.value,
                      style: pw.TextStyle(font: fontBold, fontSize: 11, color: _textColor)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── KALIMAT PENUTUP (berbeda per jenis surat) ──────────
  pw.Widget _buildPenutup(PengajuanSurat p, String tglSurat, pw.Font fontRegular) {
    final jenis = p.jenisSurat.toLowerCase();
    String penutup;

    if (jenis.contains('domisili')) {
      penutup =
          'Demikian Surat Keterangan Domisili ini kami buat dengan sebenarnya '
          'agar dapat dipergunakan sebagaimana mestinya.';
    } else if (jenis.contains('usaha')) {
      penutup =
          'Demikian Surat Keterangan Usaha ini kami buat dengan sebenarnya '
          'untuk dapat dipergunakan sebagaimana mestinya oleh yang bersangkutan.';
    } else if (jenis.contains('tidak mampu')) {
      penutup =
          'Demikian Surat Keterangan Tidak Mampu ini kami buat untuk dipergunakan '
          'sebagaimana mestinya, khususnya dalam rangka memperoleh layanan sosial '
          'dan pendidikan yang dibutuhkan.';
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          penutup,
          style: pw.TextStyle(font: fontRegular, fontSize: 11, lineSpacing: 3.5),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Dikeluarkan di : Hutabulu Mejan',
          style: pw.TextStyle(font: fontRegular, fontSize: 11),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Pada tanggal   : $tglSurat',
          style: pw.TextStyle(font: fontRegular, fontSize: 11),
        ),
      ],
    );
  }

  // ── TANDA TANGAN ───────────────────────────────────────
  pw.Widget _buildTandaTangan(String tglSurat, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Kepala Desa Hutabulu Mejan,',
                style: pw.TextStyle(font: fontRegular, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text(tglSurat,
                style: pw.TextStyle(font: fontRegular, fontSize: 11)),
            pw.SizedBox(height: 56),
            pw.Container(
              width: 160, height: 1.2,
              color: _textColor,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '( ......................................... )',
              style: pw.TextStyle(font: fontRegular, fontSize: 11),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'NIP: .......................................',
              style: pw.TextStyle(font: fontRegular, fontSize: 10, color: _mutedColor),
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
}