import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../api_config/api_config.dart';
import '../services/auth_service.dart';
import '../models/persyaratan_model.dart';
import '../services/pengajuan_service.dart' as pengajuan_service;
import '../services/offline_database_service.dart';

class FormPengajuanSuratPage extends StatefulWidget {
  final int jenisSuratId;
  final String namaSurat;
  final String? editPengajuanId;
  final Map<String, String>? existingData;

  const FormPengajuanSuratPage({
    super.key,
    required this.jenisSuratId,
    required this.namaSurat,
    this.editPengajuanId,
    this.existingData,
  });

  bool get isEditMode => editPengajuanId != null;

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
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoadingFamily = true;

  @override
  void initState() {
    super.initState();
    _fetchPersyaratan();
    // Jika mode edit, muat data existing ke draft agar terisi otomatis
    if (widget.isEditMode && widget.existingData != null) {
      _preloadExistingData();
    }
  }

  /// Muat data existing ke draft lokal untuk pre-fill saat edit
  Future<void> _preloadExistingData() async {
    if (widget.existingData == null) return;
    // Draft akan di-load oleh _fetchPersyaratan -> _initFieldState
    // Simpan data ke _existingDataCache agar _initFieldState bisa mencocokkan
    _existingDataCache = widget.existingData;
  }

  Map<String, String>? _existingDataCache;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ── AUTOFILL UTILITIES ──────────────────────────────────────────
  String _getAutoFillValue(String label) {
    return '';
  }

  bool _isNikField(String label) {
    final lower = label.toLowerCase().trim();
    return lower == 'nik' ||
        lower.contains('no. nik') ||
        lower.contains('no.nik') ||
        lower.contains('nomor nik') ||
        lower.contains('nomor induk kependudukan') ||
        lower == 'n i k' ||
        lower == 'no ktp' ||
        lower == 'no. ktp' ||
        lower == 'nomor ktp' ||
        lower == 'ktp' ||
        lower.contains('no. ktp') ||
        lower.contains('nomor ktp') ||
        lower.contains('no ktp');
  }

  bool _isCheckingNik = false;

  Future<void> _checkAndAutoFillNik(String nik, String nikFieldId) async {
    if (nik.length != 16) return;
    if (_isCheckingNik) return;

    setState(() {
      _isCheckingNik = true;
    });

    // Tampilkan Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563eb)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Memverifikasi NIK...',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mengambil data penduduk secara otomatis',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final token = AuthService().token;
    if (token == null) {
      if (mounted) Navigator.pop(context); // Tutup dialog
      setState(() {
        _isCheckingNik = false;
      });
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/penduduk/nik/$nik');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        Navigator.pop(context); // Tutup dialog
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          final data = body['data'];
          final namaLengkap = data['nama_lengkap'] ?? '';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('NIK Teridentifikasi: $namaLengkap'),
                backgroundColor: const Color(0xFF16a34a),
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Update other fields in form
          for (final model in _persyaratan) {
            final keyStr = model.id.toString();
            final fieldLabel = model.namaField.toLowerCase().trim();

            if (keyStr == nikFieldId) continue;

            if (fieldLabel == 'nama' || fieldLabel == 'nama lengkap' || fieldLabel.contains('nama pemohon') || fieldLabel.contains('nama lengkap pemohon')) {
              if (data['nama_lengkap'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['nama_lengkap'];
              }
            } else if (fieldLabel == 'alamat' || fieldLabel.contains('alamat ktp') || fieldLabel.contains('alamat lengkap') || fieldLabel.contains('alamat domisili')) {
              if (data['alamat'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['alamat'];
              }
            } else if (fieldLabel == 'pekerjaan' || fieldLabel.contains('pekerjaan')) {
              if (data['pekerjaan'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['pekerjaan'];
              }
            } else if (fieldLabel == 'tempat lahir' || fieldLabel.contains('tempat lahir') || fieldLabel == 'tempat_lahir') {
              if (data['tempat_lahir'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['tempat_lahir'];
              }
            } else if (fieldLabel == 'tanggal lahir' || fieldLabel.contains('tanggal lahir') || fieldLabel == 'tanggal_lahir' || fieldLabel == 'tgl_lahir') {
              if (data['tanggal_lahir'] != null) {
                if (model.tipeField == 'date') {
                  setState(() {
                    _answers[keyStr] = data['tanggal_lahir'];
                  });
                } else if (_controllers[keyStr] != null) {
                  _controllers[keyStr]!.text = data['tanggal_lahir'];
                }
              }
            } else if (fieldLabel == 'jenis kelamin' || fieldLabel == 'kelamin' || fieldLabel.contains('jenis kelamin') || fieldLabel == 'gender') {
              if (data['jenis_kelamin'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['jenis_kelamin'];
              }
            } else if (fieldLabel == 'agama' || fieldLabel.contains('agama')) {
              if (data['agama'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['agama'];
              }
            } else if (fieldLabel == 'kk' || fieldLabel.contains('no. kk') || fieldLabel.contains('nomor kk') || fieldLabel.contains('nomor kartu keluarga')) {
              if (data['no_kk'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['no_kk'];
              }
            } else if (fieldLabel == 'nama ayah' || fieldLabel.contains('nama_ayah') || fieldLabel == 'ayah') {
              if (data['nama_ayah'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['nama_ayah'];
              }
            } else if (fieldLabel == 'nama ibu' || fieldLabel.contains('nama_ibu') || fieldLabel == 'ibu') {
              if (data['nama_ibu'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['nama_ibu'];
              }
            } else if (fieldLabel == 'suku' || fieldLabel.contains('suku')) {
              if (data['suku'] != null && _controllers[keyStr] != null) {
                _controllers[keyStr]!.text = data['suku'];
              }
            }
          }
          _saveDraft();
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('NIK tidak ditemukan di database desa.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog jika error
      }
      debugPrint("Error checking NIK: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNik = false;
        });
      }
    }
  }

  Future<void> _fetchFamilyMembers() async {
    final token = AuthService().token;
    if (token == null) return;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/my-kk');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null && body['data']['anggota'] != null) {
          final List rawList = body['data']['anggota'];
          if (mounted) {
            setState(() {
              _familyMembers = List<Map<String, dynamic>>.from(rawList);
              _isLoadingFamily = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching family members: $e");
    }

    if (mounted) {
      setState(() {
        _isLoadingFamily = false;
      });
    }
  }

  void _autoFillFromFamilyData(String nik, String nikFieldId) {
    final member = _familyMembers.firstWhere((m) => m['nik'] == nik, orElse: () => {});
    if (member.isEmpty) return;

    final namaLengkap = member['nama_lengkap'] ?? '';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Memilih data keluarga: $namaLengkap'),
          backgroundColor: const Color(0xFF16a34a),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Update other fields in form
    for (final model in _persyaratan) {
      final keyStr = model.id.toString();
      final fieldLabel = model.namaField.toLowerCase().trim();

      if (keyStr == nikFieldId) continue;

      if (fieldLabel == 'nama' || fieldLabel == 'nama lengkap' || fieldLabel.contains('nama pemohon') || fieldLabel.contains('nama lengkap pemohon')) {
        if (member['nama_lengkap'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['nama_lengkap'];
        }
      } else if (fieldLabel == 'alamat' || fieldLabel.contains('alamat ktp') || fieldLabel.contains('alamat lengkap') || fieldLabel.contains('alamat domisili')) {
        if (member['alamat'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['alamat'];
        }
      } else if (fieldLabel == 'pekerjaan' || fieldLabel.contains('pekerjaan')) {
        if (member['pekerjaan'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['pekerjaan'];
        }
      } else if (fieldLabel == 'tempat lahir' || fieldLabel.contains('tempat lahir') || fieldLabel == 'tempat_lahir') {
        if (member['tempat_lahir'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['tempat_lahir'];
        }
      } else if (fieldLabel == 'tanggal lahir' || fieldLabel.contains('tanggal lahir') || fieldLabel == 'tanggal_lahir' || fieldLabel == 'tgl_lahir') {
        if (member['tanggal_lahir'] != null) {
          String tglVal = member['tanggal_lahir'].toString();
          if (tglVal.contains('T')) {
            tglVal = tglVal.split('T')[0];
          }
          if (model.tipeField == 'date') {
            setState(() {
              _answers[keyStr] = tglVal;
            });
          } else if (_controllers[keyStr] != null) {
            _controllers[keyStr]!.text = tglVal;
          }
        }
      } else if (fieldLabel == 'jenis kelamin' || fieldLabel == 'kelamin' || fieldLabel.contains('jenis kelamin') || fieldLabel == 'gender') {
        if (member['jenis_kelamin'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['jenis_kelamin'];
        }
      } else if (fieldLabel == 'agama' || fieldLabel.contains('agama')) {
        if (member['agama'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['agama'];
        }
      } else if (fieldLabel == 'kk' || fieldLabel.contains('no. kk') || fieldLabel.contains('nomor kk') || fieldLabel.contains('nomor kartu keluarga')) {
        if (member['no_kk'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['no_kk'];
        }
      } else if (fieldLabel == 'nama ayah' || fieldLabel.contains('nama_ayah') || fieldLabel == 'ayah') {
        if (member['nama_ayah'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['nama_ayah'];
        }
      } else if (fieldLabel == 'nama ibu' || fieldLabel.contains('nama_ibu') || fieldLabel == 'ibu') {
        if (member['nama_ibu'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['nama_ibu'];
        }
      } else if (fieldLabel == 'suku' || fieldLabel.contains('suku')) {
        if (member['suku'] != null && _controllers[keyStr] != null) {
          _controllers[keyStr]!.text = member['suku'];
        }
      }
    }
    _saveDraft();
  }


  // ── PERSISTENT FORM DRAFTS UTILITIES ─────────────────────────────
  Future<void> _saveDraft() async {
    final Map<String, String> draftMap = {};
    _controllers.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        draftMap[key] = controller.text.trim();
      }
    });

    _answers.forEach((key, value) {
      if (value is String && value.isNotEmpty) {
        draftMap[key] = value;
      } else if (value is XFile) {
        draftMap[key] = '[FILE_PATH]${value.path}';
      }
    });

    await OfflineDatabaseService().simpanDraftPengajuan(widget.jenisSuratId, draftMap);
  }

  /// Mencocokkan data existing dari pengajuan lama ke ID persyaratan
  String? _matchExistingData(PersyaratanSuratModel model) {
    if (_existingDataCache == null) return null;
    // Cari berdasarkan nama field (case-insensitive)
    for (final entry in _existingDataCache!.entries) {
      if (entry.key.trim().toLowerCase() == model.namaField.trim().toLowerCase()) {
        // Skip file fields
        if (entry.value.startsWith('[Unggahan Foto]') || entry.value.startsWith('[FILE_PATH]')) {
          return null;
        }
        return entry.value;
      }
    }
    return null;
  }

  Future<void> _initFieldState(PersyaratanSuratModel model, Map<String, String> draft) async {
    final keyStr = model.id.toString();
    final draftVal = draft[keyStr];
    // Jika mode edit, coba ambil data existing
    final existingVal = _matchExistingData(model);

    if (model.tipeField == 'text' || model.tipeField == 'number') {
      final initialVal = draftVal ?? existingVal ?? _getAutoFillValue(model.namaField);
      
      if (_controllers[keyStr] == null) {
        final controller = TextEditingController(text: initialVal);
        _controllers[keyStr] = controller;
        controller.addListener(_saveDraft);

        if (_isNikField(model.namaField)) {
          controller.addListener(() {
            final text = controller.text.trim();
            if (text.length == 16) {
              final isFamilyMember = _familyMembers.any((m) => m['nik'] == text);
              if (isFamilyMember) {
                _autoFillFromFamilyData(text, keyStr);
              } else {
                _checkAndAutoFillNik(text, keyStr);
              }
            }
          });

          if (initialVal.length == 16) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final isFamilyMember = _familyMembers.any((m) => m['nik'] == initialVal);
              if (isFamilyMember) {
                _autoFillFromFamilyData(initialVal, keyStr);
              } else {
                _checkAndAutoFillNik(initialVal, keyStr);
              }
            });
          }
        }
      } else {
        if (_controllers[keyStr]!.text.isEmpty && initialVal.isNotEmpty) {
          _controllers[keyStr]!.text = initialVal;
        }
      }
    } else if (model.tipeField == 'date') {
      if (draftVal != null) {
        _answers[keyStr] = draftVal;
      } else if (existingVal != null) {
        _answers[keyStr] = existingVal;
      } else if (_answers[keyStr] == null) {
        final lower = model.namaField.toLowerCase();
        if (lower.contains('tanggal lahir') || 
            lower.contains('tgl lahir') || 
            lower.contains('tgl. lahir') || 
            lower.contains('tgl_lahir')) {
          final user = AuthService().currentUser;
          if (user != null && user.tanggalLahir != null) {
            final tgl = user.tanggalLahir!;
            final formatted = "${tgl.year}-${tgl.month.toString().padLeft(2, '0')}-${tgl.day.toString().padLeft(2, '0')}";
            _answers[keyStr] = formatted;
          }
        }
      }
    } else if (model.tipeField == 'file_image') {
      if (draftVal != null && draftVal.startsWith('[FILE_PATH]') && _answers[keyStr] == null) {
        final filePath = draftVal.replaceFirst('[FILE_PATH]', '');
        final file = File(filePath);
        if (await file.exists()) {
          _answers[keyStr] = XFile(filePath);
        }
      }
    }
  }

  // ── LOAD DYNAMIC REQUIREMENTS FROM API ──────────────────────────
  Future<void> _fetchPersyaratan() async {
    _fetchFamilyMembers();
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
      await AuthService().fetchLatestProfile();
    } catch (e) {
      debugPrint('Silent profile sync error in form: $e');
    }

    final draft = await OfflineDatabaseService().ambilDraftPengajuan(widget.jenisSuratId);

    // 1. Ambil data dari cache lokal terlebih dahulu (Local-First Read)
    final localData = await OfflineDatabaseService().ambilPersyaratan(widget.jenisSuratId);
    if (localData.isNotEmpty) {
      final List<PersyaratanSuratModel> loaded = [];
      for (var item in localData) {
        final model = PersyaratanSuratModel.fromJson(item);
        loaded.add(model);
        await _initFieldState(model, draft);
      }

      setState(() {
        _persyaratan = loaded;
        _isLoadingRequirements = false;
        _errorMessage = null;
      });
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/dynamic/persyaratan/${widget.jenisSuratId}');
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
          final List<PersyaratanSuratModel> loaded = [];

          for (var item in rawList) {
            final model = PersyaratanSuratModel.fromJson(item);
            loaded.add(model);
            await _initFieldState(model, draft);
          }

          setState(() {
            _persyaratan = loaded;
            _isLoadingRequirements = false;
            _errorMessage = null;
          });

          final List<Map<String, dynamic>> cacheList = rawList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          await OfflineDatabaseService().simpanPersyaratan(widget.jenisSuratId, cacheList);
        } else {
          if (_persyaratan.isEmpty) {
            setState(() {
              _isLoadingRequirements = false;
              _errorMessage = body['message'] ?? 'Gagal mengambil persyaratan surat.';
            });
          }
        }
      } else {
        if (_persyaratan.isEmpty) {
          setState(() {
            _isLoadingRequirements = false;
            _errorMessage = 'Kesalahan server (${response.statusCode}). Silakan coba lagi.';
          });
        }
      }
    } catch (e) {
      if (_persyaratan.isEmpty) {
        setState(() {
          _isLoadingRequirements = false;
          _errorMessage = 'Koneksi terputus. Periksa jaringan internet atau server Anda.';
        });
      }
      debugPrint('Error fetching persyaratan: $e');
    }
  }

  // ── DATE PICKER DIALOG ACTION ─────────────────────────────────
  Future<void> _pickDate(String persyaratanId, String fieldLabel) async {
    DateTime initialDate = DateTime.now();
    
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
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _answers[persyaratanId] = formatted;
      });
      _saveDraft();
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
        _saveDraft();
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
    _saveDraft();
  }

  // ── SUBMIT MULTIPART FORM DATA ─────────────────────────────────
  Future<void> _submitForm() async {
    _controllers.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        _answers[key] = controller.text.trim();
      } else {
        _answers.remove(key);
      }
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua isian wajib yang masih kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    final authService = AuthService();
    final token = authService.token;
    if (token == null) {
      _showErrorDialog('Sesi login telah kedaluwarsa. Silakan login kembali.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Tentukan URL: jika edit mode, gunakan endpoint update
      final isEdit = widget.isEditMode;
      final url = isEdit
          ? Uri.parse('${ApiConfig.baseUrl}/dynamic/pengajuan/${widget.editPengajuanId}')
          : Uri.parse('${ApiConfig.baseUrl}/dynamic/pengajuan');
      
      final request = http.MultipartRequest('POST', url);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (!isEdit) {
        request.fields['jenis_surat_id'] = widget.jenisSuratId.toString();
      }

      for (final entry in _answers.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is XFile) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'answers[$key]',
              value.path,
            ),
          );
        } else if (value != null && value.toString().isNotEmpty) {
          request.fields['answers[$key]'] = value.toString();
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Submit dynamic form status: ${response.statusCode}');
      debugPrint('Submit dynamic form body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
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

        if (!isEdit) {
          pengajuan_service.PengajuanService().tambahPengajuan(
            jenisSuratId: widget.jenisSuratId,
            jenisSurat: widget.namaSurat,
            emoji: _getEmojiForSurat(widget.namaSurat),
            data: localFormData,
          );
        }

        await OfflineDatabaseService().hapusDraftPengajuan(widget.jenisSuratId);

        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      } else {
        setState(() => _isSubmitting = false);
        final errMsg = responseData['message'] ?? (isEdit ? 'Gagal memperbarui pengajuan surat.' : 'Gagal memproses pengajuan surat ke server.');
        _showErrorDialog(errMsg);
      }
    } catch (e) {
      if (widget.isEditMode) {
        // Mode edit tidak support offline queue — tampilkan error
        setState(() => _isSubmitting = false);
        _showErrorDialog('Gagal memperbarui pengajuan. Periksa koneksi internet Anda dan coba lagi.');
        return;
      }

      debugPrint('Koneksi bermasalah saat mengirim pengajuan, menyimpan ke antrean offline: $e');
      
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

      final Map<String, dynamic> serializableAnswers = {};
      _answers.forEach((key, value) {
        if (value is XFile) {
          serializableAnswers[key] = '[FILE_PATH]${value.path}';
        } else {
          serializableAnswers[key] = value;
        }
      });

      await pengajuan_service.PengajuanService().tambahPengajuanOffline(
        jenisSuratId: widget.jenisSuratId.toString(),
        jenisSuratNama: widget.namaSurat,
        emoji: _getEmojiForSurat(widget.namaSurat),
        answers: serializableAnswers,
        localFormData: localFormData,
      );

      await OfflineDatabaseService().hapusDraftPengajuan(widget.jenisSuratId);

      setState(() => _isSubmitting = false);
      _showSuccessDialog();
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
              Text(
                widget.isEditMode ? 'Pengajuan Diperbarui! ✏️' : 'Pengajuan Dikirim! 🎉',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isEditMode
                    ? 'Permohonan ${widget.namaSurat} Anda telah berhasil diperbarui. Mohon pantau status pengajuan secara berkala di menu riwayat.'
                    : 'Permohonan ${widget.namaSurat} Anda telah berhasil dikirim ke server desa. Mohon pantau status pengajuan secara berkala di menu riwayat.',
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
            if (_isNikField(field.namaField)) ...[
              if (_isLoadingFamily) ...[
                DropdownButtonFormField<String>(
                  initialValue: null,
                  items: const [],
                  onChanged: null,
                  decoration: InputDecoration(
                    hintText: "Memuat data keluarga...",
                    hintStyle: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
                    fillColor: const Color(0xFFf8fafc),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563eb))),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ] else if (_familyMembers.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    String? selectedValue;
                    final currentText = _controllers[keyStr]?.text.trim() ?? '';
                    final exists = _familyMembers.any((m) => m['nik'] == currentText);
                    if (exists) {
                      selectedValue = currentText;
                    } else if (currentText.isEmpty && _familyMembers.isNotEmpty) {
                      final userNik = AuthService().currentUser?.nik ?? '';
                      final userMember = _familyMembers.firstWhere((m) => m['nik'] == userNik, orElse: () => _familyMembers.first);
                      selectedValue = userMember['nik'];
                      _controllers[keyStr]?.text = selectedValue ?? '';
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _autoFillFromFamilyData(selectedValue!, keyStr);
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: selectedValue,
                      style: const TextStyle(
                        fontSize: 14, 
                        color: Color(0xFF1e293b),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: "Pilih NIK Keluarga",
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
                          borderSide: const BorderSide(
                            color: Color(0xFF2563eb), 
                            width: 1.5,
                          ),
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
                      items: _familyMembers.map((member) {
                        final nik = member['nik'] ?? '';
                        final nama = member['nama_lengkap'] ?? '';
                        return DropdownMenuItem<String>(
                          value: nik,
                          child: Text(
                            "$nik - $nama",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _controllers[keyStr]?.text = val;
                          });
                          _autoFillFromFamilyData(val, keyStr);
                        }
                      },
                      validator: (val) {
                        if (field.isRequired && (val == null || val.trim().isEmpty)) {
                          return "NIK wajib dipilih.";
                        }
                        return null;
                      },
                    );
                  }
                ),
              ] else ...[
                TextFormField(
                  controller: _controllers[keyStr],
                  keyboardType: field.tipeField == 'number' ? TextInputType.number : TextInputType.text,
                  style: const TextStyle(
                    fontSize: 14, 
                    color: Color(0xFF1e293b),
                  ),
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
                      borderSide: const BorderSide(
                        color: Color(0xFF2563eb), 
                        width: 1.5,
                      ),
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
              ],
            ] else ...[
              TextFormField(
                controller: _controllers[keyStr],
                keyboardType: field.tipeField == 'number' ? TextInputType.number : TextInputType.text,
                style: const TextStyle(
                  fontSize: 14, 
                  color: Color(0xFF1e293b),
                ),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF2563eb), 
                      width: 1.5,
                    ),
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
            ],
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

  // ── GENDER SELECTOR CHIP WIDGET ───────────────────────────────
  Widget _buildGenderSelector(String keyStr, bool isRequired) {
    final selected = _answers[keyStr]?.toString();
    final isError = isRequired && selected == null;

    const lakilaki = 'Laki-laki';
    const perempuan = 'Perempuan';

    Widget buildChip(String label, IconData icon, Color activeColor) {
      final isActive = selected == label;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _answers[keyStr] = label;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? activeColor : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? activeColor : (isError ? Colors.red.shade300 : Colors.grey.shade200),
                width: isActive ? 2.0 : 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isActive ? Colors.white : activeColor,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓ Dipilih',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            buildChip(lakilaki, Icons.male_rounded, const Color(0xFF2563eb)),
            const SizedBox(width: 12),
            buildChip(perempuan, Icons.female_rounded, const Color(0xFFdb2777)),
          ],
        ),
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Jenis kelamin wajib dipilih.',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748b)),
                const SizedBox(width: 4),
                Text(
                  'Diisi otomatis dari data profil Anda. Ketuk untuk mengubah.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8), height: 1.4),
                ),
              ],
            ),
          ),
      ],
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
                Text(
                  widget.isEditMode ? 'Edit Formulir Pengajuan' : 'Formulir Persyaratan Dinamis',
                  style: TextStyle(
                    color: Color(0xFF1e3a8a),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditMode
                      ? 'Ubah data yang perlu diperbaiki lalu kirim ulang permohonan surat "${widget.namaSurat}".'
                      : 'Lengkapi semua berkas dan isian berikut dengan benar untuk pengajuan surat "${widget.namaSurat}".',
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
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isEditMode ? 'Memperbarui Pengajuan...' : 'Mengirim Pengajuan...',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isEditMode ? Icons.save_rounded : Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEditMode ? 'Simpan Perubahan' : 'Kirim Permohonan Surat',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
