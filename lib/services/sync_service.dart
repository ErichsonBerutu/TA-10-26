// lib/services/sync_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_config/api_config.dart';
import './offline_database_service.dart';
import './auth_service.dart';
import './pengaduan_service.dart';
import './pengajuan_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _db = OfflineDatabaseService();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Memeriksa apakah koneksi internet atau server backend tersedia
  Future<bool> checkInternet() async {
    try {
      // Coba lookup host backend API
      final uri = Uri.parse(ApiConfig.baseUrl);
      final result = await InternetAddress.lookup(uri.host).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        // Coba ping google.com sebagai alternatif
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Memproses semua antrean offline (Sync Queue) secara sekuensial
  Future<void> processSyncQueue() async {
    if (_isSyncing) return;

    final queue = await _db.ambilSyncQueue();
    if (queue.isEmpty) {
      debugPrint('SyncService: Antrean kosong. Tidak ada data untuk disinkronkan.');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final isOnline = await checkInternet();
      if (!isOnline) {
        debugPrint('SyncService: Jaringan offline atau server tidak dapat dijangkau. Menunda sinkronisasi.');
        _isSyncing = false;
        notifyListeners();
        return;
      }

      final token = AuthService().token;
      if (token == null) {
        debugPrint('SyncService: Sesi login belum aktif/token kosong. Menunda sinkronisasi.');
        _isSyncing = false;
        notifyListeners();
        return;
      }

      debugPrint('SyncService: Mendeteksi ${queue.length} item di antrean lokal. Memulai pengunggahan...');

      // Buat salinan antrean agar tidak terjadi modifikasi list saat looping
      final itemsToSync = List<Map<String, dynamic>>.from(queue);

      for (final item in itemsToSync) {
        final id = item['id'];
        final action = item['action'];
        final Map<String, dynamic> payload = Map<String, dynamic>.from(item['payload']);

        bool success = false;

        if (action == 'tambah_pengaduan') {
          success = await _syncPengaduan(payload, token);
        } else if (action == 'tambah_pengajuan') {
          success = await _syncPengajuan(payload, token);
        }

        if (success) {
          // Hapus dari antrean lokal jika berhasil disinkronkan ke Laravel
          await _db.hapusDariSyncQueue(id);
          debugPrint('SyncService: Item $id ($action) berhasil disinkronkan dan dihapus dari antrean.');
        } else {
          // Jika gagal karena error validasi/server (bukan jaringan), hentikan loop agar tidak loop selamanya
          debugPrint('SyncService: Item $id ($action) gagal disinkronkan. Menunda sisa antrean.');
          break;
        }
      }

      // Refresh data lokal di service terkait setelah proses sinkronisasi selesai
      await PengaduanService().muatRiwayatPengaduan();
      await PengajuanService().muatDaftarPengajuan();

    } catch (e) {
      debugPrint('ERROR SyncService.processSyncQueue: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sinkronisasi item Pengaduan ke Server
  Future<bool> _syncPengaduan(Map<String, dynamic> payload, String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pengaduan');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['judul'] = payload['judul']?.toString() ?? ''
        ..fields['deskripsi'] = payload['deskripsi']?.toString() ?? ''
        ..fields['jenis'] = payload['jenis']?.toString() ?? '';

      final fotoPath = payload['fotoPath']?.toString();
      if (fotoPath != null && fotoPath.isNotEmpty) {
        final file = File(fotoPath);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('foto', fotoPath));
        } else {
          debugPrint('SyncService: Berkas foto pengaduan tidak ditemukan di: $fotoPath');
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ERROR SyncService._syncPengaduan: $e');
      return false;
    }
  }

  /// Sinkronisasi item Pengajuan Surat ke Server
  Future<bool> _syncPengajuan(Map<String, dynamic> payload, String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/dynamic/pengajuan');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['jenis_surat_id'] = payload['jenis_surat_id']?.toString() ?? '';

      final Map<String, dynamic> answers = Map<String, dynamic>.from(payload['answers'] ?? {});
      for (final entry in answers.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String && value.startsWith('[FILE_PATH]')) {
          // Format penyimpanan offline untuk berkas: '[FILE_PATH]/path/to/file'
          final filePath = value.replaceFirst('[FILE_PATH]', '');
          final file = File(filePath);
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath('answers[$key]', filePath));
          } else {
            debugPrint('SyncService: Berkas pengajuan tidak ditemukan di: $filePath');
            // Tetap tambahkan teks keterangan kosong agar form tidak terblokir
            request.fields['answers[$key]'] = '[Berkas Tidak Ditemukan saat Sinkronisasi Offline]';
          }
        } else if (value != null) {
          request.fields['answers[$key]'] = value.toString();
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ERROR SyncService._syncPengajuan: $e');
      return false;
    }
  }
}
