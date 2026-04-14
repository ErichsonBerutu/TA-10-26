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

  const ProfilePage({required this.user, required this.authService, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _editedUser;
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _noHpCtrl;
  late TextEditingController _alamatCtrl;

  @override
  void initState() {
    super.initState();
    _editedUser = widget.user;
    _namaCtrl = TextEditingController(text: _editedUser.nama);
    _emailCtrl = TextEditingController(text: _editedUser.email);
    _noHpCtrl = TextEditingController(text: _editedUser.noHp);
    _alamatCtrl = TextEditingController(text: _editedUser.alamat);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _noHpCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      _namaCtrl.text = _editedUser.nama;
      _emailCtrl.text = _editedUser.email;
      _noHpCtrl.text = _editedUser.noHp;
      _alamatCtrl.text = _editedUser.alamat;
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final updated = _editedUser.copyWith(
      nama: _namaCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
    );

    final success = await widget.authService.updateProfile(updated);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _editedUser = updated;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Color(0xFF16a34a),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil'),
            backgroundColor: Color(0xFFdc2626),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              widget.authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFdc2626)),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(AppNavItem item) {
    if (item == AppNavItem.beranda) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BerandaPage()),
      );
    } else if (item == AppNavItem.surat) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuratPage()),
      );
    } else if (item == AppNavItem.pengaduan) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PengaduanPage()),
      );
    } else if (item == AppNavItem.pengumuman) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PengumumanPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    _buildEditForm(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF1e40af), Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x661e40af),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Kelola informasi akun Anda',
                  style: TextStyle(color: Color(0x99ffffff), fontSize: 11),
                ),
              ],
            ),
          ),
          const Text('', style: TextStyle(fontSize: 26)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(90, 16, 90, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563eb).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563eb).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _editedUser.nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK: ${_editedUser.nik}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0f172a),
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: _toggleEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563eb).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2563eb).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        color: const Color(0xFF2563eb),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isEditing ? 'Batal' : 'Edit',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563eb),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Nama Lengkap',
            controller: _namaCtrl,
            enabled: _isEditing,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Email',
            controller: _emailCtrl,
            enabled: _isEditing,
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Nomor Telepon',
            controller: _noHpCtrl,
            enabled: _isEditing,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            label: 'Alamat',
            controller: _alamatCtrl,
            enabled: _isEditing,
            icon: Icons.location_on_rounded,
            maxLines: 3,
          ),
          if (_editedUser.jenisKelamin != null) ...[
            const SizedBox(height: 14),
            _buildInfoField(
              label: 'Jenis Kelamin',
              value: _editedUser.jenisKelamin!,
              icon: Icons.wc_rounded,
            ),
          ],
          if (_editedUser.tanggalLahir != null) ...[
            const SizedBox(height: 14),
            _buildInfoField(
              label: 'Tanggal Lahir',
              value:
                  '${_editedUser.tanggalLahir!.day} ${_bulanNama(_editedUser.tanggalLahir!.month)} ${_editedUser.tanggalLahir!.year}',
              icon: Icons.calendar_today_rounded,
            ),
          ],
          const SizedBox(height: 14),
          _buildInfoField(
            label: 'Login Terakhir',
            value: _formatTanggal(_editedUser.loginAt),
            icon: Icons.access_time_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0f172a),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFf1f5f9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF2563eb).withOpacity(0.3)
                  : const Color(0xFFe2e8f0),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF2563eb), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: label,
              hintStyle: const TextStyle(
                color: Color(0xFF94a3b8),
                fontSize: 13,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0f172a),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0f172a),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFf1f5f9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFe2e8f0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF64748b), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748b),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing)
            GestureDetector(
              onTap: _isLoading ? null : _saveProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16a34a), Color(0xFF15803d)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16a34a).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          if (_isEditing) const SizedBox(height: 12),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFef4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFef4444).withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFef4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFef4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _bulanNama(int bulan) {
    const nama = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return nama[bulan - 1];
  }

  String _formatTanggal(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_bulanNama(dt.month)} ${dt.year} pukul $jam:$menit';
  }
}
