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

  const ProfilePage({super.key, required this.user, required this.authService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // =====================================================
  // LOGOUT
  // =====================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await widget.authService.logout();

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
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
          MaterialPageRoute(builder: (_) => const BerandaPage()),
        );
        break;

      case AppNavItem.surat:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuratPage()),
        );
        break;

      case AppNavItem.pengaduan:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PengaduanPage()),
        );
        break;

      case AppNavItem.pengumuman:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PengumumanPage()),
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
    final user = widget.user;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    _buildProfileCard(user),
                    _buildInfoSection(user),
                    _buildLogoutButton(),
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
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.person, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 28, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.nama,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            "Nomor KK : ${user.nik}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(User user) {
    String tanggalLahirStr = '-';
    if (user.tanggalLahir != null) {
      final tgl = user.tanggalLahir!;
      const bln = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      final blnStr = tgl.month >= 1 && tgl.month <= 12 ? bln[tgl.month] : '';
      tanggalLahirStr = "${tgl.day} $blnStr ${tgl.year}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: 'Nomor KK',
              value: user.nik,
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: 'NIK',
              value: user.noKtp.isNotEmpty ? user.noKtp : '-',
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Nama Lengkap',
              value: user.nama,
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.location_city_outlined,
              label: 'Tempat Lahir',
              value: user.tempatLahir.isNotEmpty ? user.tempatLahir : '-',
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.cake_outlined,
              label: 'Tanggal Lahir',
              value: tanggalLahirStr,
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.home_outlined,
              label: 'Alamat',
              value: user.alamat.isNotEmpty ? user.alamat : '-',
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.church_outlined,
              label: 'Agama',
              value: user.agama.isNotEmpty ? user.agama : '-',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 48,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Keluar dari Akun",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
