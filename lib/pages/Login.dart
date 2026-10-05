import 'package:flutter/material.dart';
import 'Beranda.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Palette warna tema PrekDuaDara
  static const Color bgYellow = Color(0xFFFBBF24);
  static const Color darkGreen = Color(0xFF26492C);
  static const Color textDark = Color(0xFF111111);
  static const Color subTextGrey = Color(0xFF6B7280);

  String _currentKasir = 'Nama Kasir';
  String _currentShift = 'Shift Pagi';
  String _currentShiftTime = '08:00 – 12:00 WIB';

  void _showGantiKasirDialog() {
    final kasirList = [
      {'nama': 'Rian (Kasir 01)', 'shift': 'Shift Pagi', 'waktu': '08:00 – 12:00 WIB'},
      {'nama': 'Siti (Kasir 02)', 'shift': 'Shift Siang', 'waktu': '12:00 – 17:00 WIB'},
      {'nama': 'Budi (Kasir 03)', 'shift': 'Shift Malam', 'waktu': '17:00 – 22:00 WIB'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Kasir Bertugas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 14),
                ...kasirList.map((k) {
                  final isSelected = _currentKasir == k['nama'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEBF7EE) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? darkGreen : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? darkGreen : const Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        k['nama']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isSelected ? darkGreen : textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${k['shift']} • ${k['waktu']}',
                        style: const TextStyle(fontSize: 12, color: subTextGrey),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: darkGreen)
                          : null,
                      onTap: () {
                        setState(() {
                          _currentKasir = k['nama']!;
                          _currentShift = k['shift']!;
                          _currentShiftTime = k['waktu']!;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgYellow,
      body: Stack(
        children: [
          // Background Decorative Graphics (Warm Glow Ribbons)
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginBackgroundPainter(),
            ),
          ),

          // Main Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Date & Time Pill Badge (Top Left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Senin, 14 Okt 2026',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                          Text(
                            '15:30 WIB',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Main Title
                  const Text(
                    'PrekDuaDara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 3. Avatar / Cashier Profile Graphic
                  Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        color: darkGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD6DEC9),
                          width: 8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 4. White Card: KASIR BERTUGAS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'KASIR BERTUGAS',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentKasir,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: textDark,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _currentShift,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: textDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              _currentShiftTime,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 5. Button "MULAI SHIFT"
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BerandaPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MULAI SHIFT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Button "Ganti Kasir"
                  ElevatedButton(
                    onPressed: _showGantiKasirDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: textDark,
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: textDark,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ganti Kasir',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 7. Home Indicator bar (white pill at bottom)
                  Center(
                    child: Container(
                      width: screenSize.width * 0.38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Background painter with authentic gaussian-blurred bokeh glows matching the design
class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base vibrant warm yellow background
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFDC332),
          Color(0xFFFBBF24),
          Color(0xFFF5A40C),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Large top-right soft blurred orange glow
    final glowTopRight = Paint()
      ..color = const Color(0xFFE86014).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 75.0);
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.12),
      size.width * 0.45,
      glowTopRight,
    );

    // 3. Diagonal soft blurred orange beam
    final glowBeam = Paint()
      ..color = const Color(0xFFE57E25).withValues(alpha: 0.60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65.0);
    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 1.1, 0)
      ..lineTo(size.width * 1.1, size.height * 0.30)
      ..lineTo(size.width * -0.2, size.height * 0.58)
      ..lineTo(size.width * -0.2, size.height * 0.34)
      ..close();
    canvas.drawPath(path, glowBeam);

    // 4. Middle-left soft blurred orange bokeh orb
    final glowMidLeft = Paint()
      ..color = const Color(0xFFE6731B).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55.0);
    canvas.drawCircle(
      Offset(size.width * 0.02, size.height * 0.44),
      size.width * 0.32,
      glowMidLeft,
    );

    // 5. Lower-left soft warm amber glow
    final glowBottomLeft = Paint()
      ..color = const Color(0xFFE28A18).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60.0);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.80),
      size.width * 0.28,
      glowBottomLeft,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

