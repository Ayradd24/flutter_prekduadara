import 'dart:ui';
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';

// Palette warna konsisten tema PrekDuaDara
const Color bgYellow = Color(0xFFFBBF24);
const Color primaryGreen = Color(0xFF1E6F38);
const Color ribbonOrange = Color(0xFFE57E25);
const Color textDark = Color(0xFF111111);
const Color cardGrey = Color(0xFFE5E7EB);
const Color subTextGrey = Color(0xFF6B7280);

class MenuItemData {
  final String id;
  final String title;
  final String category;
  final int price;
  final int? originalPrice;
  final String defaultNote;
  final String imageUrl;

  MenuItemData({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.defaultNote,
    required this.imageUrl,
  });
}

class OrderItem {
  final MenuItemData menuItem;
  int quantity;
  String note;

  OrderItem({
    required this.menuItem,
    required this.quantity,
    required this.note,
  });

  int get totalPrice => menuItem.price * quantity;
}

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategory = 'Semua';
  String _paymentMethod = 'Tunai';

  final List<String> _categories = [
    'Semua',
    'Geprek Bakar',
    'Geprek Biasa',
  ];

  final List<MenuItemData> _allMenuItems = [
    MenuItemData(
      id: '1',
      title: 'Ayam Geprek Bakar + Es Teh',
      category: 'Geprek Bakar',
      price: 18000,
      defaultNote: '',
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=300&q=80',
    ),
    MenuItemData(
      id: '2',
      title: 'Ayam Geprek Biasa + Es Teh',
      category: 'Geprek Biasa',
      price: 17000,
      defaultNote: '',
      imageUrl:
          'https://images.unsplash.com/photo-1562967914-608f82629710?w=300&q=80',
    ),
  ];

  // List of active ordered items (dimulai dari 0)
  final List<OrderItem> _orderedItems = [];

  // Helper formatting for Indonesian Rupiah
  String _formatCurrency(int amount) {
    String str = amount.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = '.$result';
        count = 0;
      }
    }
    return 'Rp $result';
  }

  int get _subtotal {
    int total = 0;
    for (var item in _orderedItems) {
      total += item.totalPrice;
    }
    return total;
  }

  int get _tax => (_subtotal * 0.1).round();
  int get _grandTotal => _subtotal + _tax;

  void _addMenuItem(MenuItemData item) {
    setState(() {
      final index = _orderedItems.indexWhere((o) => o.menuItem.id == item.id);
      if (index >= 0) {
        _orderedItems[index].quantity += 1;
      } else {
        _orderedItems.add(
          OrderItem(
            menuItem: item,
            quantity: 1,
            note: item.defaultNote,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} ditambahkan ke pesanan!'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _decrementOrderItem(int index) {
    setState(() {
      if (_orderedItems[index].quantity > 1) {
        _orderedItems[index].quantity -= 1;
      } else {
        _orderedItems.removeAt(index);
      }
    });
  }

  void _incrementOrderItem(int index) {
    setState(() {
      _orderedItems[index].quantity += 1;
    });
  }

  void _showNoteDialog(OrderItem orderItem) {
    final controller = TextEditingController(text: orderItem.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Catatan ${orderItem.menuItem.title}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Contoh: Pedas Lv 3, Ekstra Sambal, Tanpa Es...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: subTextGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                orderItem.note = controller.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: primaryGreen, size: 54),
            const SizedBox(height: 12),
            const Text(
              'Pesanan Berhasil Disimpan!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Metode Pembayaran: $_paymentMethod\nStruk dicetak ke Thermal ESC/POS Printer (${_formatCurrency(_grandTotal)})',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: subTextGrey, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _orderedItems.clear();
                });
              },
              child:
                  const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRISDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, color: primaryGreen, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Pembayaran QRIS',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: subTextGrey),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Total Tagihan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: subTextGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _grandTotal > 0 ? _formatCurrency(_grandTotal) : 'Rp 0',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 155,
                              color: textDark,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryGreen, width: 2),
                              ),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                size: 18,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'NMID: ID1029384756201\nPREK DUA DARA KASIR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: subTextGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Tunggu pelanggan scan dan menyelesaikan pembayaran QRIS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Button: Sudah Bayar & Cetak Struk
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSuccessDialog();
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'SUDAH BAYAR & CETAK STRUK',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePrintAndSave() {
    if (_orderedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 menu untuk pesanan'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_paymentMethod == 'QRIS') {
      _showQRISDialog();
    } else {
      _showSuccessDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final filteredMenu = _selectedCategory == 'Semua'
        ? _allMenuItems
        : _allMenuItems.where((m) => m.category == _selectedCategory).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgYellow,
      endDrawer: const AppDrawer(currentPage: 'transaksi'),
      body: Stack(
        children: [
          // Background Decorative Graphics (Diagonal Orange Ribbons)
          Positioned.fill(
            child: CustomPaint(
              painter: _TransaksiBackgroundPainter(),
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
                        // Pesanan Baru Title
                        _buildSubHeaderRow(),
                        const SizedBox(height: 12),

                        // Category Chips
                        _buildCategoryFilter(),
                        const SizedBox(height: 14),

                        // Section Header (Pilih Menu Populer / 24 Menu Tersedia)
                        _buildSectionHeader(),
                        const SizedBox(height: 10),

                        // Menu Items List
                        ...filteredMenu.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildMenuCard(item),
                            )),

                        const SizedBox(height: 4),

                        // Pesanan Card
                        if (_orderedItems.isNotEmpty) ...[
                          _buildPesananCard(),
                          const SizedBox(height: 14),
                        ],

                        // Payment Method Selector
                        _buildPaymentMethodSelector(),
                        const SizedBox(height: 14),

                        // Subtotal & Summary Card
                        _buildSummaryCard(),
                        const SizedBox(height: 14),

                        // Print and Save Button
                        _buildPrintButton(),
                        const SizedBox(height: 10),

                        // Printer Ready Status
                        _buildPrinterStatus(),
                        const SizedBox(height: 20),

                        // Bottom Home Indicator Pill
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
            'Transaksi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.3,
            ),
          ),

          // 3 Green Lines Hamburger Button
          HamburgerMenuButton(
            onTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
    );
  }

  // --- Sub Header: Pesanan Baru ---
  Widget _buildSubHeaderRow() {
    return const Row(
      children: [
        Icon(Icons.circle, color: textDark, size: 9),
        SizedBox(width: 6),
        Text(
          'PESANAN BARU',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // --- Category Filter Chips ---
  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.black : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Section Header: PILIH MENU POPULER ---
  Widget _buildSectionHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PILIH MENU POPULER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '2 Menu Tersedia',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF78350F),
          ),
        ),
      ],
    );
  }

  // --- Menu Item Card ---
  Widget _buildMenuCard(MenuItemData item) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.network(
                    item.imageUrl,
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

              // Title & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(item.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textDark,
                          ),
                        ),
                        if (item.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(item.originalPrice!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // [+] Add Button
              InkWell(
                onTap: () => _addMenuItem(item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: textDark,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom Note Clickable Row (Entire area is clickable)
          InkWell(
            onTap: () {
              final existingIndex = _orderedItems.indexWhere((o) => o.menuItem.id == item.id);
              if (existingIndex >= 0) {
                _showNoteDialog(_orderedItems[existingIndex]);
              } else {
                final newItem = OrderItem(
                  menuItem: item,
                  quantity: 1,
                  note: '',
                );
                setState(() {
                  _orderedItems.add(newItem);
                });
                _showNoteDialog(newItem);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Builder(
                builder: (context) {
                  final orderItem = _orderedItems.where((o) => o.menuItem.id == item.id).firstOrNull;
                  final currentNote = (orderItem != null && orderItem.note.isNotEmpty)
                      ? orderItem.note
                      : null;

                  return Row(
                    children: [
                      Icon(
                        currentNote != null
                            ? Icons.edit_note_rounded
                            : Icons.add_comment_outlined,
                        size: 16,
                        color: currentNote != null ? primaryGreen : subTextGrey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentNote != null
                              ? 'Catatan: $currentNote'
                              : 'Tambahkan catatan khusus...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: currentNote != null ? FontWeight.w700 : FontWeight.w500,
                            color: currentNote != null ? textDark : subTextGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: subTextGrey,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Payment Method Selector Card ---
  Widget _buildPaymentMethodSelector() {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'METODE PEMBAYARAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Tunai Option
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _paymentMethod = 'Tunai';
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'Tunai'
                          ? primaryGreen
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'Tunai'
                            ? primaryGreen
                            : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 20,
                          color: _paymentMethod == 'Tunai'
                              ? Colors.white
                              : textDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tunai',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _paymentMethod == 'Tunai'
                                ? Colors.white
                                : textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // QRIS Option
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _paymentMethod = 'QRIS';
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'QRIS'
                          ? primaryGreen
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'QRIS'
                            ? primaryGreen
                            : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 20,
                          color: _paymentMethod == 'QRIS'
                              ? Colors.white
                              : textDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'QRIS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _paymentMethod == 'QRIS'
                                ? Colors.white
                                : textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Pesanan Card ---
  Widget _buildPesananCard() {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: PESANAN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PESANAN (${_orderedItems.length} Jenis)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ordered Items List
          ..._orderedItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final order = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title & Price note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.menuItem.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@ ${_formatCurrency(order.menuItem.price)} · Lv 3',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Stepper: [-] 1 [+]
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _decrementOrderItem(idx),
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Icon(Icons.remove,
                                    size: 16, color: textDark),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '${order.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _incrementOrderItem(idx),
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child:
                                    Icon(Icons.add, size: 16, color: textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatCurrency(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Subtotal & Grand Total Summary Card ---
  Widget _buildSummaryCard() {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              Text(
                _formatCurrency(_subtotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Pajak Resto (10%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pajak Resto (10%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              Text(
                _formatCurrency(_tax),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFF3F4F6), thickness: 1),
          ),

          // TOTAL AKHIR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL AKHIR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Termasuk PPN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: subTextGrey,
                    ),
                  ),
                ],
              ),
              Text(
                _formatCurrency(_grandTotal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Print & Save Button ---
  Widget _buildPrintButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _handlePrintAndSave,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_outlined, size: 20),
            SizedBox(width: 8),
            Text(
              '+ SIMPAN & CETAK STRUK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Printer Ready Status Footer ---
  Widget _buildPrinterStatus() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 15,
            color: Color(0xFF92400E),
          ),
          SizedBox(width: 4),
          Text(
            'Thermal ESC/POS Printer Siap (Kasir 01)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Diagonal Ribbons Background
class _TransaksiBackgroundPainter extends CustomPainter {
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
