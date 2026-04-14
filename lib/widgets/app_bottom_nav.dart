import 'package:flutter/material.dart';

enum AppNavItem { beranda, surat, pengaduan, pengumuman, profil }

class AppBottomNav extends StatelessWidget {
  final AppNavItem current;
  final ValueChanged<AppNavItem> onTap;

  const AppBottomNav({required this.current, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (item: AppNavItem.beranda, label: 'Beranda', icon: Icons.home_rounded),
      (item: AppNavItem.surat, label: 'Surat', icon: Icons.description_rounded),
      (
        item: AppNavItem.pengaduan,
        label: 'Pengaduan',
        icon: Icons.chat_bubble_rounded,
      ),
      (
        item: AppNavItem.pengumuman,
        label: 'Pengumuman',
        icon: Icons.campaign_rounded,
      ),
      (item: AppNavItem.profil, label: 'Profil', icon: Icons.person_rounded),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF1e40af), Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x661e40af),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: navItems.map((entry) {
              final active = entry.item == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(entry.item),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 44,
                        height: 30,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          entry.icon,
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.45),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.label,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: active ? 0.2 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
