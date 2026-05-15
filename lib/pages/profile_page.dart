import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';

import 'beranda_page.dart';
import 'pengaduan_page.dart';
import 'pengumuman_page.dart';
import 'surat_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const ProfilePage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _editedUser;

  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nikCtrl;
  late TextEditingController _namaCtrl;
  late TextEditingController _tempatLahirCtrl;
  late TextEditingController _tanggalLahirCtrl;
  late TextEditingController _alamatCtrl;

  @override
  void initState() {
    super.initState();

    _editedUser = widget.user;

    _nikCtrl = TextEditingController(text: _editedUser.nik);
    _namaCtrl = TextEditingController(text: _editedUser.nama);
    _tempatLahirCtrl =
        TextEditingController(text: _editedUser.tempatLahir);
    _tanggalLahirCtrl = TextEditingController(
      text: _editedUser.tanggalLahir != null
          ? _editedUser.tanggalLahir!
              .toIso8601String()
              .split('T')[0]
          : '',
    );
    _alamatCtrl =
        TextEditingController(text: _editedUser.alamat);
  }

  @override
  void dispose() {
    _nikCtrl.dispose();
    _namaCtrl.dispose();
    _tempatLahirCtrl.dispose();
    _tanggalLahirCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  // =====================================================
  // TOGGLE EDIT
  // =====================================================

  void _toggleEdit() {
    if (_isEditing) {
      _nikCtrl.text = _editedUser.nik;
      _namaCtrl.text = _editedUser.nama;
      _tempatLahirCtrl.text =
          _editedUser.tempatLahir;

      _tanggalLahirCtrl.text =
          _editedUser.tanggalLahir != null
              ? _editedUser.tanggalLahir!
                  .toIso8601String()
                  .split('T')[0]
              : '';

      _alamatCtrl.text = _editedUser.alamat;
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // =====================================================
  // SAVE PROFILE
  // =====================================================

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final updatedUser = _editedUser.copyWith(
      nik: _nikCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      tempatLahir:
          _tempatLahirCtrl.text.trim(),
      tanggalLahir: DateTime.tryParse(
        _tanggalLahirCtrl.text.trim(),
      ),
      alamat: _alamatCtrl.text.trim(),
    );

    final success =
        await widget.authService.updateProfile(
      updatedUser,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _editedUser = updatedUser;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Gagal memperbarui profil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              widget.authService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginPage(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style:
                  TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  void _onBottomNavTap(AppNavItem item) {
    switch (item) {
      case AppNavItem.beranda:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const BerandaPage(),
          ),
        );
        break;

      case AppNavItem.surat:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SuratPage(),
          ),
        );
        break;

      case AppNavItem.pengaduan:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PengaduanPage(),
          ),
        );
        break;

      case AppNavItem.pengumuman:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PengumumanPage(),
          ),
        );
        break;

      case AppNavItem.profil:
        break;
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.only(
                  bottom: 30,
                ),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    _buildFormSection(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavItem.profil,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.person,
              color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin:
          const EdgeInsets.all(16),
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                const Color(
                    0xFF2563EB),
            child: Text(
              _editedUser
                      .nama.isNotEmpty
                  ? _editedUser
                      .nama[0]
                      .toUpperCase()
                  : 'U',
              style:
                  const TextStyle(
                fontSize: 28,
                color:
                    Colors.white,
              ),
            ),
          ),
          const SizedBox(
              height: 12),
          Text(
            _editedUser.nama,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(
              height: 4),
          Text(
            "NIK : ${_editedUser.nik}",
            style:
                const TextStyle(
              color:
                  Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
              horizontal: 16),
      child: Column(
        children: [
          _buildField(
            label: "NIK",
            controller: _nikCtrl,
            enabled: false,
          ),
          _buildField(
            label:
                "Nama Lengkap",
            controller:
                _namaCtrl,
            enabled:
                _isEditing,
          ),
          _buildField(
            label:
                "Tempat Lahir",
            controller:
                _tempatLahirCtrl,
            enabled:
                _isEditing,
          ),
          _buildField(
            label:
                "Tanggal Lahir",
            controller:
                _tanggalLahirCtrl,
            enabled:
                _isEditing,
          ),
          _buildField(
            label: "Alamat",
            controller:
                _alamatCtrl,
            enabled:
                _isEditing,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController
        controller,
    required bool enabled,
    int maxLines = 1,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
              bottom: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration:
            InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled
              ? Colors.white
              : const Color(
                  0xFFF8FAFC),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius
                    .circular(
                        12),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding:
          const EdgeInsets.all(
              16),
      child: Column(
        children: [
          if (!_isEditing)
            ElevatedButton(
              onPressed:
                  _toggleEdit,
              style:
                  ElevatedButton
                      .styleFrom(
                minimumSize:
                    const Size
                        .fromHeight(
                            48),
              ),
              child:
                  const Text(
                "Edit Profil",
              ),
            ),
          if (_isEditing)
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : _saveProfile,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.green,
                minimumSize:
                    const Size
                        .fromHeight(
                            48),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors
                          .white,
                    )
                  : const Text(
                      "Simpan"),
            ),
          const SizedBox(
              height: 12),
          OutlinedButton(
            onPressed:
                _logout,
            style:
                OutlinedButton
                    .styleFrom(
              minimumSize:
                  const Size
                      .fromHeight(
                          48),
              foregroundColor:
                  Colors.red,
            ),
            child: const Text(
                "Logout"),
          ),
        ],
      ),
    );
  }
}