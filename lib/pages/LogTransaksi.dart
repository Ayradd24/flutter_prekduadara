import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import 'Login.dart';

// Palette warna konsisten tema PrekDuaDara
const Color bgYellow = Color(0xFFFBBF24);
const Color primaryGreen = Color(0xFF1E6F38);
const Color ribbonOrange = Color(0xFFE57E25);
const Color textDark = Color(0xFF111111);
const Color cardGrey = Color(0xFFE5E7EB);
const Color subTextGrey = Color(0xFF6B7280);

class TransactionItem {
  final String id;
  final String time;
  final String status;
  final String items;
  final String paymentMethod;
  final String cashier;
  final int totalAmount;

  TransactionItem({
    required this.id,
    required this.time,
    required this.status,
    required this.items,
    required this.paymentMethod,
    required this.cashier,
    required this.totalAmount,
  });
}

class LogTransaksiPage extends StatefulWidget {
  const LogTransaksiPage({super.key});

  @override
  State<LogTransaksiPage> createState() => _LogTransaksiPageState();
}

class _LogTransaksiPageState extends State<LogTransaksiPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'Semua';

  final List<TransactionItem> _allTransactions = [
    TransactionItem(
      id: '#TRX-1029',
      time: '14:25',
      status: 'LUNAS',
      items: '2× Ayam Geprek Bakar + Es Teh',
      paymentMethod: 'QRIS',
      cashier: 'Kasir: Siti',
      totalAmount: 39600,
    ),
    TransactionItem(
      id: '#TRX-1028',
      time: '14:10',
      status: 'LUNAS',
      items: '1× Ayam Geprek Biasa + Es Teh',
      paymentMethod: 'TUNAI',
      cashier: 'Kasir: Siti',
      totalAmount: 18700,
    ),
    TransactionItem(
      id: '#TRX-1027',
      time: '13:45',
      status: 'LUNAS',
      items: '3× Ayam Geprek Bakar + Es Teh',
      paymentMethod: 'QRIS',
      cashier: 'Kasir: Siti',
      totalAmount: 59400,
    ),
    TransactionItem(
      id: '#TRX-1026',
      time: '13:15',
      status: 'LUNAS',
      items: '2× Ayam Geprek Biasa + Es Teh',
      paymentMethod: 'TUNAI',
      cashier: 'Kasir: Siti',
      totalAmount: 37400,
    ),
    TransactionItem(
      id: '#TRX-1025',
      time: '12:50',
      status: 'LUNAS',
      items: '1× Ayam Geprek Bakar + Es Teh, 1× Ayam Geprek Biasa + Es Teh',
      paymentMethod: 'QRIS',
      cashier: 'Kasir: Siti',
      totalAmount: 38500,
    ),
  ];

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _handleDownloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.download_done_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Rekap transaksi berhasil diunduh (PDF/Excel)'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleCloseShift() {
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
          style: TextStyle(fontSize: 13, color: subTextGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: subTextGrey)),
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
                  backgroundColor: primaryGreen,
                ),
              );
            },
            child: const Text('Tutup Shift', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilter == 'Semua'
        ? _allTransactions
        : _allTransactions
            .where((t) => t.paymentMethod.toUpperCase() == _selectedFilter.toUpperCase())
            .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgYellow,
      endDrawer: const AppDrawer(currentPage: 'log_transaksi'),
      body: Stack(
        children: [
          // Background Decorative Graphics (Diagonal Orange Ribbons)
          Positioned.fill(
            child: CustomPaint(
              painter: _LogTransaksiBackgroundPainter(),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Header Bar
                _buildHeader(),

                // 2. Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pesanan Harian Title & Date
                        _buildPesananHarianRow(),
                        const SizedBox(height: 12),

                        // Total Omset Hari Ini Card
                        _buildOmsetCard(),
                        const SizedBox(height: 16),

                        // Filter Chips (Semua, Tunai, QRIS)
                        _buildFilterChips(),
                        const SizedBox(height: 14),

                        // Transactions List
                        ...filteredList.map((trx) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTransactionCard(trx),
                            )),

                        // Validasi Akhir Shift Section
                        _buildValidasiShiftSection(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Log Transaksi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.3,
            ),
          ),
          HamburgerMenuButton(
            onTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
    );
  }

  // --- Pesanan Harian Row ---
  Widget _buildPesananHarianRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan Harian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Sinkronisasi Lokal Aktif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: textDark),
              SizedBox(width: 6),
              Text(
                '11 Okt 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Total Omset Card ---
  Widget _buildOmsetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Shift Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL OMSET HARI INI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: subTextGrey,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: textDark, size: 6),
                    SizedBox(width: 5),
                    Text(
                      'Shift Pagi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Amount
          const Text(
            'Rp 1.450.000',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Status Row
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 15, color: subTextGrey),
              SizedBox(width: 5),
              Text(
                '32 Transaksi Selesai',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: subTextGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-segment Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: 65,
                    child: Container(color: textDark),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: 35,
                    child: Container(color: const Color(0xFFD1D5DB)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.square, size: 10, color: textDark),
                  SizedBox(width: 6),
                  Text(
                    'Tunai: Rp 942.500\n(65%)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.square, size: 10, color: Color(0xFFD1D5DB)),
                  SizedBox(width: 6),
                  Text(
                    'QRIS: Rp 507.500\n(35%)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Filter Chips ---
  Widget _buildFilterChips() {
    final chips = [
      {'label': 'Semua (32)', 'key': 'Semua'},
      {'label': 'Tunai (21)', 'key': 'Tunai'},
      {'label': 'QRIS (11)', 'key': 'QRIS'},
    ];

    return Row(
      children: chips.map((c) {
        final isSelected = _selectedFilter == c['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedFilter = c['key']!;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c['label']!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Transaction Card ---
  Widget _buildTransactionCard(TransactionItem trx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID, Time, LUNAS badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    trx.id,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subTextGrey,
                      ),
                    ),
                  ),
                  Text(
                    trx.time,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: subTextGrey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trx.status,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items Ordered Description
          Text(
            trx.items,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Row: Payment Method badge, Cashier, Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: trx.paymentMethod == 'QRIS' ? Colors.black : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      trx.paymentMethod,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: trx.paymentMethod == 'QRIS' ? Colors.white : textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trx.cashier,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subTextGrey,
                    ),
                  ),
                ],
              ),
              Text(
                _formatCurrency(trx.totalAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Validasi Akhir Shift Section ---
  Widget _buildValidasiShiftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VALIDASI AKHIR SHIFT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Kasir: Siti Aminah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Download Rekap Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: textDark,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _handleDownloadReport,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, size: 19),
                SizedBox(width: 8),
                Text(
                  'Download Rekap PDF / Excel',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tutup Shift Sekarang Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _handleCloseShift,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 19),
                SizedBox(width: 8),
                Text(
                  'TUTUP SHIFT SEKARANG',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Background Painter with Diagonal Orange Ribbons
class _LogTransaksiBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = ribbonOrange.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFFD97018).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Diagonal Band 1
    final path1 = Path()
      ..moveTo(size.width * 0.45, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..lineTo(0, size.height * 0.38)
      ..lineTo(0, size.height * 0.16)
      ..close();
    canvas.drawPath(path1, paint1);

    // Diagonal Band 2 (Accent)
    final path2 = Path()
      ..moveTo(size.width * 0.75, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.14)
      ..lineTo(0, size.height * 0.30)
      ..lineTo(0, size.height * 0.22)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
