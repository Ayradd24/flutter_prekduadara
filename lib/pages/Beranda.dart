import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../widget/app_drawer.dart';
import 'Transaksi.dart';
import 'LogTransaksi.dart';

// Palette warna konsisten tema PrekDuaDara
const Color bgYellow = Color(0xFFFBBF24);
const Color primaryGreen = Color(0xFF1E6F38);
const Color ribbonOrange = Color(0xFFE57E25);
const Color textDark = Color(0xFF111111);
const Color subTextGrey = Color(0xFF6B7280);
const Color qrisBlue = Color(0xFF2563EB);

class BerandaPage extends StatefulWidget {
  final String? currentKasir;
  final String? currentShift;

  const BerandaPage({
    super.key,
    this.currentKasir,
    this.currentShift,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _effectiveKasir {
    if (widget.currentKasir != null && widget.currentKasir!.isNotEmpty && widget.currentKasir != 'Pilih Kasir') {
      return widget.currentKasir!;
    }
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 12) return 'Rian';
    if (hour >= 12 && hour < 17) return 'Siti';
    return 'Budi';
  }

  String get _effectiveShift {
    if (widget.currentShift != null && widget.currentShift!.isNotEmpty && widget.currentShift != '-') {
      return widget.currentShift!;
    }
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 12) return 'Shift Pagi';
    if (hour >= 12 && hour < 17) return 'Shift Siang';
    return 'Shift Malam';
  }

  // Map of item quantities added
  final Map<String, int> _itemCounts = {
    'Ayam Geprek Bakar + Es Teh': 0,
    'Ayam Geprek Biasa + Es Teh': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadProductsFromDatabase();
  }

  Future<void> _loadProductsFromDatabase() async {
    try {
      final dbProducts = await AppDatabase.instance.getAllProducts();
      if (mounted && dbProducts.isNotEmpty) {
        setState(() {
          for (var p in dbProducts) {
            _itemCounts.putIfAbsent(p.name, () => 0);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading products from local db: $e');
    }
  }

  void _addItem(String name, int price) {
    setState(() {
      _itemCounts[name] = (_itemCounts[name] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name ditambahkan ke pesanan!'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _removeItem(String name) {
    setState(() {
      final current = _itemCounts[name] ?? 0;
      if (current > 0) {
        _itemCounts[name] = current - 1;
      }
    });
  }

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgYellow,
      endDrawer: AppDrawer(
        currentPage: 'beranda',
        currentKasir: _effectiveKasir,
        currentShift: _effectiveShift,
      ),
      body: Stack(
        children: [
          // Background Decorative Graphics (Diagonal Orange Ribbons)
          Positioned.fill(
            child: CustomPaint(
              painter: _BerandaBackgroundPainter(),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Top Bar / Header
                _buildHeader(),

                // 2. Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cashier Status Card
                        _buildCashierStatusCard(),
                        const SizedBox(height: 12),

                        // Omset Shift Card
                        _buildOmsetCard(),
                        const SizedBox(height: 16),

                        // Menu Section Header
                        _buildMenuHeader(),
                        const SizedBox(height: 10),

                        // Menu Item 1: Geprek Bakar + Es Teh
                        _buildMenuItemCard(
                          title: 'Ayam Geprek Bakar + Es Teh',
                          description:
                              'Nasi + Ayam Geprek Bakar + Es Teh',
                          price: 18000,
                          imageUrl: 'assets/images/geprek_bakar.jpg',
                        ),
                        const SizedBox(height: 12),

                        // Menu Item 2: Geprek Biasa + Es Teh
                        _buildMenuItemCard(
                          title: 'Ayam Geprek Biasa + Es Teh',
                          description:
                              'Nasi + Ayam Geprek Biasa + Es Teh',
                          price: 17000,
                          imageUrl: 'assets/images/geprek_biasa.jpg',
                        ),
                        const SizedBox(height: 16),

                        // Tombol Konfirmasi dan Bayar
                        _buildConfirmPayButton(),
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
            'Beranda',
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

  // --- Cashier Status Card ---
  Widget _buildCashierStatusCard() {
    final namaKasir = _effectiveKasir.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 15,
                  color: textDark,
                ),
                const SizedBox(width: 5),
                Text(
                  'Kasir: $namaKasir',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Omset Shift Card ---
  Widget _buildOmsetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: 19,
                    color: Color(0xFF1D4ED8),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Omset Shift Saat Ini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _effectiveShift,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Amount
          const Text(
            'Rp 1.450.000',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Completed Transactions Count
          const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 15,
                color: Color(0xFF4B5563),
              ),
              SizedBox(width: 5),
              Text(
                '32 Transaksi Selesai',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual-segment Progress Bar (Green + Blue)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  // Tunai Segment (Green)
                  Expanded(
                    flex: 95,
                    child: Container(color: primaryGreen),
                  ),
                  const SizedBox(width: 2),
                  // QRIS Segment (Blue)
                  Expanded(
                    flex: 50,
                    child: Container(color: qrisBlue),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 7, color: primaryGreen),
                  ),
                  SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tunai: Rp 950.000',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        '21 Transaksi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subTextGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 7, color: qrisBlue),
                  ),
                  SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QRIS: Rp 500.000',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: qrisBlue,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        '11 Transaksi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subTextGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Menu Section Header ---
  Widget _buildMenuHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: textDark,
                ),
                SizedBox(width: 4),
                Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogTransaksiPage(
                      currentKasir: _effectiveKasir,
                      currentShift: _effectiveShift,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Log Transaksi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: textDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text(
          'Tap (+) untuk menambahkan cepat ke pesanan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
      ],
    );
  }

  // --- Menu Item Card ---
  Widget _buildMenuItemCard({
    required String title,
    required String description,
    required int price,
    required String imageUrl,
  }) {
    final count = _itemCounts[title] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(
                            Icons.fastfood_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(
                            Icons.fastfood_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Description & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: subTextGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRupiah(price),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Count & Controls (Minus if count > 0, Count, Plus)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count > 0) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _removeItem(title),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: textDark,
                      size: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _addItem(title, price),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Confirm & Pay Button ---
  Widget _buildConfirmPayButton() {
    final totalCount = _itemCounts.values.fold(0, (sum, count) => sum + count);
    final bool hasOrder = totalCount > 0;
    int totalPrice = 0;
    totalPrice += (_itemCounts['Ayam Geprek Bakar + Es Teh'] ?? 0) * 18000;
    totalPrice += (_itemCounts['Ayam Geprek Biasa + Es Teh'] ?? 0) * 17000;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (!hasOrder) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Harus ada pesanan terpilih sebelum konfirmasi!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            return;
          }

          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => TransaksiPage(
                initialItemCounts: _itemCounts,
              ),
            ),
          );

          if (result == true && mounted) {
            setState(() {
              _itemCounts.updateAll((key, value) => 0);
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KONFIRMASI & BAYAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (hasOrder)
                      Text(
                        '$totalCount Item · ${_formatRupiah(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD1FAE5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Diagonal Ribbons Background
class _BerandaBackgroundPainter extends CustomPainter {
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
