import 'package:flutter/material.dart';
import '../pages/Beranda.dart';
import '../pages/Transaksi.dart';
import '../pages/LogTransaksi.dart';
import '../pages/Login.dart';

// Palette warna khusus Drawer sesuai desain
const Color drawerBgDarkGreen = Color(0xFF26492C);
const Color drawerYellow = Color(0xFFFBBF24);
const Color drawerLogoutBg = Color(0xFF627D56);
const Color drawerLogoutRed = Color(0xFFDC2626);

class AppDrawer extends StatelessWidget {
  final String currentPage;

  const AppDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Drawer width disesuaikan agar tidak full halaman (sekitar 68% - 72% layar atau maks 280px)
    final drawerWidth = (screenWidth * 0.72).clamp(240.0, 290.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: drawerBgDarkGreen,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // 1. Garis vertikal kuning di sisi kiri drawer
            Positioned(
              left: 12,
              top: 16,
              bottom: 16,
              child: Container(
                width: 7,
                decoration: BoxDecoration(
                  color: drawerYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 2. Konten Menu Drawer
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 20, top: 48, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tombol BERANDA
                  _buildDrawerButton(
                    context: context,
                    text: 'BERANDA',
                    bgColor: drawerYellow,
                    textColor: drawerBgDarkGreen,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'beranda') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BerandaPage(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Tombol TRANSAKSI
                  _buildDrawerButton(
                    context: context,
                    text: 'TRANSAKSI',
                    bgColor: drawerYellow,
                    textColor: drawerBgDarkGreen,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'transaksi') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransaksiPage(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Tombol LOG TRANSAKSI
                  _buildDrawerButton(
                    context: context,
                    text: 'LOG TRANSAKSI',
                    bgColor: drawerYellow,
                    textColor: drawerBgDarkGreen,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentPage != 'log_transaksi') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LogTransaksiPage(),
                          ),
                        );
                      }
                    },
                  ),

                  const Spacer(),

                  // Tombol TUTUP SHIFT
                  _buildDrawerButton(
                    context: context,
                    text: 'TUTUP SHIFT',
                    bgColor: drawerLogoutBg,
                    textColor: drawerLogoutRed,
                    onTap: () {
                      _showConfirmCloseShiftDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmCloseShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Tutup Shift',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menutup shift saat ini? Total omset dan transaksi akan direkap secara otomatis.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close Drawer
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shift berhasil ditutup!'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF1E6F38),
                ),
              );
            },
            child: const Text('Tutup Shift', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerButton({
    required BuildContext context,
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// Widget reusable untuk tombol 3 garis hijau (Hamburger) di header kanan atas
class HamburgerMenuButton extends StatelessWidget {
  final VoidCallback? onTap;

  const HamburgerMenuButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              Scaffold.of(ctx).openEndDrawer();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 30,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6F38),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4.5),
                Container(
                  width: 30,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6F38),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4.5),
                Container(
                  width: 30,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6F38),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

