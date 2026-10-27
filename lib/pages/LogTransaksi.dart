import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import 'Login.dart';
import 'Beranda.dart';

// Palette warna konsisten tema PrekDuaDara
const Color bgYellow = Color(0xFFFBBF24);
const Color primaryGreen = Color(0xFF1E6F38);
const Color ribbonOrange = Color(0xFFE57E25);
const Color textDark = Color(0xFF111111);
const Color cardGrey = Color(0xFFE5E7EB);
const Color subTextGrey = Color(0xFF6B7280);
const Color qrisBlue = Color(0xFF2563EB);

class TransactionItemDetail {
  final String name;
  final int quantity;
  final int price;

  TransactionItemDetail({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class TransactionItem {
  final String id;
  final String time;
  final String status;
  final String items;
  final String paymentMethod;
  final String cashier;
  final int totalAmount;
  final int subtotal;
  final int tax;
  final int cashReceived;
  final int change;
  final List<TransactionItemDetail> details;

  TransactionItem({
    required this.id,
    required this.time,
    required this.status,
    required this.items,
    required this.paymentMethod,
    required this.cashier,
    required this.totalAmount,
    required this.subtotal,
    required this.tax,
    this.cashReceived = 0,
    this.change = 0,
    required this.details,
  });
}

class LogTransaksiPage extends StatefulWidget {
  final String? currentKasir;
  final String? currentShift;

  const LogTransaksiPage({
    super.key,
    this.currentKasir,
    this.currentShift,
  });

  @override
  State<LogTransaksiPage> createState() => _LogTransaksiPageState();
}

class _LogTransaksiPageState extends State<LogTransaksiPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'Semua';

  final Set<String> _expandedTrxIds = {};

  String get _effectiveKasir {
    if (widget.currentKasir != null &&
        widget.currentKasir!.isNotEmpty &&
        widget.currentKasir != 'Pilih Kasir') {
      return widget.currentKasir!;
    }
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 12) return 'Rian';
    if (hour >= 12 && hour < 17) return 'Siti';
    return 'Budi';
  }

  String get _effectiveShift {
    if (widget.currentShift != null &&
        widget.currentShift!.isNotEmpty &&
        widget.currentShift != '-') {
      return widget.currentShift!;
    }
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 12) return 'Shift Pagi';
    if (hour >= 12 && hour < 17) return 'Shift Siang';
    return 'Shift Malam';
  }

  String get _namaKasir =>
      _effectiveKasir.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

  List<TransactionItem> get _allTransactions => [
    TransactionItem(
      id: '#TRX-1029',
      time: '14:25',
      status: 'LUNAS',
      items: '2× Ayam Geprek Bakar + Es Teh',
      paymentMethod: 'QRIS',
      cashier: 'Kasir: $_namaKasir',
      subtotal: 36000,
      tax: 3600,
      totalAmount: 39600,
      cashReceived: 39600,
      change: 0,
      details: [
        TransactionItemDetail(
          name: 'Paket Geprek Bakar (Lv 2)',
          quantity: 2,
          price: 36000,
        ),
      ],
    ),
    TransactionItem(
      id: '#TRX-1028',
      time: '14:10',
      status: 'LUNAS',
      items: '1× Ayam Geprek Biasa + Es Teh',
      paymentMethod: 'TUNAI',
      cashier: 'Kasir: $_namaKasir',
      subtotal: 17000,
      tax: 1700,
      totalAmount: 18700,
      cashReceived: 20000,
      change: 1300,
      details: [
        TransactionItemDetail(
          name: 'Paket Geprek Biasa (Lv 3)',
          quantity: 1,
          price: 17000,
        ),
      ],
    ),
    TransactionItem(
      id: '#TRX-1027',
      time: '13:45',
      status: 'LUNAS',
      items: '3× Ayam Geprek Bakar + Es Teh',
      paymentMethod: 'QRIS',
      cashier: 'Kasir: $_namaKasir',
      subtotal: 54000,
      tax: 5400,
      totalAmount: 59400,
      cashReceived: 59400,
      change: 0,
      details: [
        TransactionItemDetail(
          name: 'Paket Geprek Bakar (Lv 5)',
          quantity: 3,
          price: 54000,
        ),
      ],
    ),
    TransactionItem(
      id: '#TRX-1026',
      time: '13:15',
      status: 'LUNAS',
      items: '2× Ayam Geprek Biasa + Es Teh',
      paymentMethod: 'TUNAI',
      cashier: 'Kasir: $_namaKasir',
      subtotal: 34000,
      tax: 3400,
      totalAmount: 37400,
      cashReceived: 50000,
      change: 12600,
      details: [
        TransactionItemDetail(
          name: 'Paket Geprek Biasa (Lv 1)',
          quantity: 2,
          price: 34000,
        ),
      ],
    ),
    TransactionItem(
      id: '#TRX-1025',
      time: '12:50',
      status: 'LUNAS',
      items: '1× Ayam Geprek Bakar + Es Teh, 1× Ayam Geprek Biasa + Es Teh',
      paymentMethod: 'QRIS',
      cashier: 'Kasir: $_namaKasir',
      subtotal: 35000,
      tax: 3500,
      totalAmount: 38500,
      cashReceived: 38500,
      change: 0,
      details: [
        TransactionItemDetail(
          name: 'Paket Geprek Bakar',
          quantity: 1,
          price: 18000,
        ),
        TransactionItemDetail(
          name: 'Paket Geprek Biasa',
          quantity: 1,
          price: 17000,
        ),
      ],
    ),
  ];

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _handleReprintReceipt(TransactionItem trx) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.print_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mencetak ulang struk ${trx.id}... Struk berhasil dicetak!',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
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
      endDrawer: AppDrawer(
        currentPage: 'log_transaksi',
        currentKasir: _effectiveKasir,
        currentShift: _effectiveShift,
      ),
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
                        // Tombol Kembali ke Beranda
                        _buildSubHeaderRow(),
                        const SizedBox(height: 12),

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

  // --- Sub Header: Tombol Kembali ke Beranda ---
  Widget _buildSubHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BerandaPage(
                    currentKasir: _effectiveKasir,
                    currentShift: _effectiveShift,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 15,
                  color: textDark,
                ),
                SizedBox(width: 6),
                Text(
                  'Kembali ke Beranda',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

          // Total Amount
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

          // Status Row
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

          // Multi-segment Bar (Hijau + Biru)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: 95,
                    child: Container(color: primaryGreen),
                  ),
                  const SizedBox(width: 2),
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isBold = false,
    bool highlightValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 12.5 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? textDark : const Color(0xFF4B5563),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: highlightValue
                ? primaryGreen
                : (isBold ? textDark : const Color(0xFF374151)),
          ),
        ),
      ],
    );
  }

  // --- Transaction Card ---
  Widget _buildTransactionCard(TransactionItem trx) {
    final isExpanded = _expandedTrxIds.contains(trx.id);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedTrxIds.remove(trx.id);
              } else {
                _expandedTrxIds.add(trx.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: ID, Time, LUNAS badge, and dropdown indicator arrow
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: textDark,
                          ),
                        ),
                      ],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: trx.paymentMethod == 'QRIS'
                                ? Colors.black
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            trx.paymentMethod,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: trx.paymentMethod == 'QRIS'
                                  ? Colors.white
                                  : textDark,
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

                // Detail Terbuka (Accordion / Dropdown)
                if (isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  const SizedBox(height: 12),

                  // 1. RINCIAN PESANAN
                  const Text(
                    'RINCIAN PESANAN:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...trx.details.map((detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${detail.quantity}x ${detail.name}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(detail.price),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),

                  // 2. RINCIAN PEMBAYARAN
                  const Text(
                    'RINCIAN PEMBAYARAN:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    label: 'TOTAL BAYAR',
                    value: _formatCurrency(trx.totalAmount),
                    isBold: true,
                  ),
                  const SizedBox(height: 8),

                  // Breakdown Uang Tunai / Status QRIS
                  if (trx.paymentMethod == 'TUNAI') ...[
                    _buildDetailRow(
                      label: 'Uang Diterima (Tunai)',
                      value: _formatCurrency(trx.cashReceived),
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      label: 'Uang Kembalian',
                      value: _formatCurrency(trx.change),
                      highlightValue: true,
                    ),
                  ] else ...[
                    _buildDetailRow(
                      label: 'Metode Pembayaran',
                      value: 'QRIS PrekDuaDara (Non-Tunai)',
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      label: 'Status Pembayaran',
                      value: 'LUNAS (NMID: ID10293847562)',
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  const SizedBox(height: 12),

                  // 3. Tombol CETAK ULANG STRUK
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: textDark, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color(0xFFF9FAFB),
                      ),
                      onPressed: () => _handleReprintReceipt(trx),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print_rounded, size: 17, color: textDark),
                          SizedBox(width: 8),
                          Text(
                            'CETAK ULANG STRUK',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Validasi Akhir Shift Section ---
  Widget _buildValidasiShiftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'VALIDASI AKHIR SHIFT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Kasir: $_namaKasir',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),


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
