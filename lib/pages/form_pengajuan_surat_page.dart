import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../api_config/api_config.dart';
import '../services/auth_service.dart';
import '../models/persyaratan_model.dart';
import '../services/pengajuan_service.dart' as pengajuan_service;

class FormPengajuanSuratPage extends StatefulWidget {
  final int jenisSuratId;
  final String namaSurat;

  const FormPengajuanSuratPage({
    super.key,
    required this.jenisSuratId,
    required this.namaSurat,
  });

  @override
  State<FormPengajuanSuratPage> createState() => _FormPengajuanSuratPageState();
}

class _FormPengajuanSuratPageState extends State<FormPengajuanSuratPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  List<PersyaratanSuratModel> _persyaratan = [];
  bool _isLoadingRequirements = true;
  String? _errorMessage;

  // Menyimpan state jawaban pengguna (Mapping ID Persyaratan -> Value)
  // Value bisa berupa String (untuk text, number, date) atau XFile (untuk file_image)
  final Map<String, dynamic> _answers = {};

  // Menyimpan TextControllers untuk text/number fields agar performa input lancar
  final Map<String, TextEditingController> _controllers = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchPersyaratan();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ── LOAD DYNAMIC REQUIREMENTS FROM API ──────────────────────────
  Future<void> _fetchPersyaratan() async {
    setState(() {
      _isLoadingRequirements = true;
      _errorMessage = null;
    });

    final token = AuthService().token;
    if (token == null) {
      setState(() {
        _isLoadingRequirements = false;
        _errorMessage = 'Sesi login telah kedaluwarsa. Silakan login kembali.';
      });
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/dynamic/persyaratan/${widget.jenisSuratId}');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null) {
          final List rawList = body['data'];
          final List<PersyaratanSuratModel> loaded = [];

          for (var item in rawList) {
            final model = PersyaratanSuratModel.fromJson(item);
            loaded.add(model);

            // Inisialisasi controller jika berupa input teks/angka
            if (model.tipeField == 'text' || model.tipeField == 'number') {
              _controllers[model.id.toString()] = TextEditingController();
            }
          }

          setState(() {
            _persyaratan = loaded;
            _isLoadingRequirements = false;
          });
        } else {
          setState(() {
            _isLoadingRequirements = false;
            _errorMessage = body['message'] ?? 'Gagal mengambil persyaratan surat.';
          });
        }
      } else {
        setState(() {
          _isLoadingRequirements = false;
          _errorMessage = 'Kesalahan server (${response.statusCode}). Silakan coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRequirements = false;
        _errorMessage = 'Koneksi terputus. Periksa jaringan internet atau server Anda.';
      });
      debugPrint('Error fetching persyaratan: $e');
    }
  }

  // ── DATE PICKER DIALOG ACTION ─────────────────────────────────
  Future<void> _pickDate(String persyaratanId, String fieldLabel) async {
    DateTime initialDate = DateTime.now();
    
    // Gunakan tanggal yang sudah dipilih sebelumnya sebagai tanggal awal jika ada
    if (_answers[persyaratanId] != null) {
      final parsed = DateTime.tryParse(_answers[persyaratanId]);
      if (parsed != null) initialDate = parsed;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563eb),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1e293b),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Simpan format tanggal YYYY-MM-DD
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _answers[persyaratanId] = formatted;
      });
    }
  }

  // ── IMAGE PICKER ACTION ───────────────────────────────────────
  Future<void> _pickImage(String persyaratanId) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _answers[persyaratanId] = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih gambar dari galeri.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── REMOVE PICKED IMAGE ───────────────────────────────────────
  void _removeImage(String persyaratanId) {
    setState(() {
      _answers.remove(persyaratanId);
    });
  }

  // ── SUBMIT MULTIPART FORM DATA ─────────────────────────────────
  Future<void> _submitForm() async {
    // 1. Sinkronisasi nilai controller ke Map State
    _controllers.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        _answers[key] = controller.text.trim();
      } else {
        _answers.remove(key);
      }
    });

    // 2. Validasi Form secara visual
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua isian wajib yang masih kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. Validasi Manual Tambahan untuk field Non-Text (Date & File) yang required
    for (final syarat in _persyaratan) {
      final key = syarat.id.toString();
      if (syarat.isRequired && (_answers[key] == null || _answers[key].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Persyaratan '${syarat.namaField}' wajib dilengkapi."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // 4. Verifikasi Status Login & Role
    final authService = AuthService();
    final token = authService.token;
    if (token == null) {
      _showErrorDialog('Sesi login telah kedaluwarsa. Silakan login kembali.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/dynamic/pengajuan');
      
      // Menggunakan http.MultipartRequest untuk mendukung pengiriman file
      final request = http.MultipartRequest('POST', url);
      
      // Header Autentikasi
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Parameter Dasar
      request.fields['jenis_surat_id'] = widget.jenisSuratId.toString();

      // Looping untuk menyematkan answers
      for (final entry in _answers.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is XFile) {
          // Tambahkan file gambar ke multipart
          request.files.add(
            await http.MultipartFile.fromPath(
              'answers[$key]', // Sesuai format array name di Laravel: answers[id]
              value.path,
            ),
          );
        } else if (value != null && value.toString().isNotEmpty) {
          // Tambahkan teks biasa ke multipart
          request.fields['answers[$key]'] = value.toString();
        }
      }

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Submit dynamic form status: ${response.statusCode}');
      debugPrint('Submit dynamic form body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Berhasil dikirim ke backend!
        // Konversi data lokal ke format Map<String, String> untuk sinkronisasi antarmuka riwayat offline
        final Map<String, String> localFormData = {};
        for (final syarat in _persyaratan) {
          final key = syarat.id.toString();
          final val = _answers[key];
          if (val is XFile) {
            localFormData[syarat.namaField] = '[Unggahan Foto] ${val.name}';
          } else if (val != null) {
            localFormData[syarat.namaField] = val.toString();
          }
        }

        // Tambah ke riwayat lokal responsif
        pengajuan_service.PengajuanService().tambahPengajuan(
          jenisSurat: widget.namaSurat,
          emoji: _getEmojiForSurat(widget.namaSurat),
          data: localFormData,
        );

        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      } else {
        setState(() => _isSubmitting = false);
        final errMsg = responseData['message'] ?? 'Gagal memproses pengajuan surat ke server.';
        _showErrorDialog(errMsg);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Terjadi kesalahan jaringan atau server terputus. Silakan coba lagi.');
      debugPrint('Error submit dynamic form: $e');
    }
  }

  // Helper untuk menentukan emoji yang tepat berdasarkan jenis surat
  String _getEmojiForSurat(String namaSurat) {
    final lower = namaSurat.toLowerCase();
    if (lower.contains('domisili')) return '🏠';
    if (lower.contains('usaha')) return '💼';
    if (lower.contains('nikah') || lower.contains('pernikahan')) return '💍';
    if (lower.contains('kematian') || lower.contains('meninggal')) return '⚰️';
    if (lower.contains('lahir') || lower.contains('kelahiran')) return '👶';
    if (lower.contains('miskin') || lower.contains('sktm')) return '🎟️';
    if (lower.contains('kelakuan baik') || lower.contains('skck')) return '👮';
    return '📝';
  }

  // ── ERROR DIALOG DISPLAY ───────────────────────────────────────
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Pengajuan Gagal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1e293b),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── SUCCESS DIALOG DISPLAY ─────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFdcfce7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF16a34a), size: 48),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pengajuan Dikirim! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Permohonan ${widget.namaSurat} Anda telah berhasil dikirim ke server desa. Mohon pantau status pengajuan secara berkala di menu riwayat.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748b),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(context); // Kembali ke menu utama layanan surat
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali ke Menu Layanan',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DYNAMIC BUILDER FOR FORM FIELDS ─────────────────────────────
  Widget _buildField(PersyaratanSuratModel field) {
    final keyStr = field.id.toString();

    // Pilih icon dekoratif berdasarkan tipe field
    IconData fieldIcon;
    Color iconColor;
    switch (field.tipeField) {
      case 'number':
        fieldIcon = Icons.pin_rounded;
        iconColor = const Color(0xFF16a34a);
        break;
      case 'date':
        fieldIcon = Icons.calendar_month_rounded;
        iconColor = const Color(0xFFea580c);
        break;
      case 'file_image':
        fieldIcon = Icons.image_outlined;
        iconColor = const Color(0xFFdb2777);
        break;
      default:
        fieldIcon = Icons.edit_note_rounded;
        iconColor = const Color(0xFF2563eb);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Label Field
          Row(
            children: [
              Icon(fieldIcon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: field.namaField,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1e293b),
                    ),
                    children: [
                      if (field.isRequired)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tipe Input Form Builder
          if (field.tipeField == 'text' || field.tipeField == 'number') ...[
            TextFormField(
              controller: _controllers[keyStr],
              keyboardType: field.tipeField == 'number' ? TextInputType.number : TextInputType.text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1e293b)),
              decoration: InputDecoration(
                hintText: "Masukkan ${field.namaField.toLowerCase()}",
                hintStyle: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
                fillColor: const Color(0xFFf8fafc),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563eb), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.0),
                ),
              ),
              validator: (val) {
                if (field.isRequired && (val == null || val.trim().isEmpty)) {
                  return "Isian '${field.namaField}' wajib diisi.";
                }
                return null;
              },
            ),
          ] else if (field.tipeField == 'date') ...[
            // Tampilan Custom Date Picker Selector
            InkWell(
              onTap: () => _pickDate(keyStr, field.namaField),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _answers[keyStr] != null
                          ? _answers[keyStr].toString()
                          : "Pilih tanggal kejadian/lahir",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _answers[keyStr] != null ? FontWeight.w600 : FontWeight.normal,
                        color: _answers[keyStr] != null ? const Color(0xFF1e293b) : const Color(0xFF94a3b8),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF64748b)),
                  ],
                ),
              ),
            ),
          ] else if (field.tipeField == 'file_image') ...[
            // Tampilan Area Upload Image Picker
            if (_answers[keyStr] == null) ...[
              // Desain Tombol Unggah Foto (Dashed Border effect)
              InkWell(
                onTap: () => _pickImage(keyStr),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfaf5ff),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFd8b4fe),
                      style: BorderStyle.solid,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFf3e8ff),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFFdb2777), size: 28),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Upload Foto Dokumen',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF701a75),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ketuk di sini untuk mengambil dari galeri ponsel',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9d174d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Preview Gambar terpilih
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFf1f5f9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File((_answers[keyStr] as XFile).path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Tombol Hapus Gambar Terpilih
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(keyStr),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  // Label Nama File Unggahan
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        (_answers[keyStr] as XFile).name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── HEADER HIERARCHY FOR FORM ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e40af), Color(0xFF2563eb)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x302563eb),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.namaSurat,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM DESCRIPTION BANNER ─────────────────────────────────────
  Widget _buildFormBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFeff6ff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFdbeafe)),
      ),
      child: Row(
        children: [
          const Text('📝', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formulir Persyaratan Dinamis',
                  style: TextStyle(
                    color: Color(0xFF1e3a8a),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lengkapi semua berkas dan isian berikut dengan benar untuk pengajuan surat "${widget.namaSurat}".',
                  style: const TextStyle(
                    color: Color(0xFF2563eb),
                    fontSize: 11,
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

  // ── SUBMIT BUTTON WIDGET ───────────────────────────────────────
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563eb),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94a3b8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Mengirim Pengajuan...',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Kirim Permohonan Surat',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }

  // ── MAIN WIDGET BUILDER ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoadingRequirements
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(
                            color: Color(0xFF2563eb),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memuat berkas persyaratan surat...',
                            style: TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _fetchPersyaratan,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563eb),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormBanner(),
                                const SizedBox(height: 20),
                                if (_persyaratan.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Tidak ada persyaratan khusus untuk surat ini.\nAnda dapat langsung mengirim permohonan.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFF64748b), fontSize: 13, height: 1.5),
                                      ),
                                    ),
                                  )
                                else
                                  ..._persyaratan.map((f) => _buildField(f)),
                                const SizedBox(height: 12),
                                _buildSubmitButton(),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
