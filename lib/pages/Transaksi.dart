import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/app_drawer.dart';
import 'Beranda.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/order_state_service.dart';
import '../services/settings_service.dart';

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
  final String imageUrl;
  final String description;

  MenuItemData({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.description = '',
  });
}

const List<String> kSambalOptions = [
  'Sambal Bawang',
  'Sambal Matah',
  'Sambal Tomat',
  'Sambal Ijo',
];

class OrderItem {
  final MenuItemData menuItem;
  int quantity;
  List<String?> sambalPerPortion;

  OrderItem({
    required this.menuItem,
    required this.quantity,
    List<String?>? sambalPerPortion,
    String? defaultSambal,
  }) : sambalPerPortion = sambalPerPortion ??
            List<String?>.generate(
              quantity,
              (_) => defaultSambal,
            );

  int get totalPrice => menuItem.price * quantity;

  void syncPortions({String? defaultSambal}) {
    if (sambalPerPortion.length < quantity) {
      sambalPerPortion.addAll(
        List<String?>.generate(
          quantity - sambalPerPortion.length,
          (_) => defaultSambal,
        ),
      );
    } else if (sambalPerPortion.length > quantity) {
      sambalPerPortion = sambalPerPortion.sublist(0, quantity);
    }
  }
}

class TransaksiPage extends StatefulWidget {
  final Map<String, int>? initialItemCounts;
  final String? currentKasir;
  final String? currentShift;

  const TransaksiPage({
    super.key,
    this.initialItemCounts,
    this.currentKasir,
    this.currentShift,
  });

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _paymentMethod = 'Tunai';
  bool _isTransactionCompleted = false;

  @override
  void initState() {
    super.initState();
    final Map<String, int> counts = {};
    if (widget.initialItemCounts != null && widget.initialItemCounts!.isNotEmpty) {
      counts.addAll(widget.initialItemCounts!);
    } else if (OrderStateService.hasActiveOrder) {
      counts.addAll(OrderStateService.itemCounts);
    }

    counts.forEach((title, count) {
      if (count > 0) {
        OrderStateService.setItemCount(title, count);
        final items = _allMenuItems.where((m) => m.title == title);
        if (items.isNotEmpty) {
          final item = items.first;
          final isGeprek = item.category.toLowerCase().contains('paket') ||
              item.title.toLowerCase().contains('geprek');
          final defaultSambal = isGeprek ? 'Sambal Bawang' : null;
          final savedSambal = OrderStateService.getSambalChoices(title);
          final orderItem = OrderItem(
            menuItem: item,
            quantity: count,
            sambalPerPortion: savedSambal,
            defaultSambal: defaultSambal,
          );
          _orderedItems.add(orderItem);
          OrderStateService.setSambalChoices(
            item.title,
            orderItem.sambalPerPortion,
          );
        }
      }
    });
  }

  final List<MenuItemData> _allMenuItems = [
    MenuItemData(
      id: '1',
      title: 'Ayam Geprek Bakar + Es Teh',
      category: 'Paket Menu',
      price: 18000,
      imageUrl: 'assets/images/geprek_bakar.jpg',
      description: 'Nasi + Ayam Geprek Bakar + Es Teh',
    ),
    MenuItemData(
      id: '2',
      title: 'Ayam Geprek Biasa + Es Teh',
      category: 'Paket Menu',
      price: 17000,
      imageUrl: 'assets/images/geprek_biasa.jpg',
      description: 'Nasi + Ayam Geprek Biasa + Es Teh',
    ),
    MenuItemData(
      id: '3',
      title: 'Ayam Geprek Mozzarella + Es Teh',
      category: 'Paket Menu',
      price: 22000,
      imageUrl: 'assets/images/geprek_mozzarella.jpg',
      description: 'Paket ayam geprek krispi dengan lelehan keju mozzarella, nasi & es teh sepuasnya',
    ),
    MenuItemData(
      id: '4',
      title: 'Ayam Geprek (Tanpa Nasi)',
      category: 'Tambahan',
      price: 13000,
      imageUrl: 'assets/images/geprek_tanpa_nasi.jpg',
      description: 'Potongan ayam geprek krispi tanpa nasi',
    ),
    MenuItemData(
      id: '5',
      title: 'Tahu & Tempe Geprek',
      category: 'Tambahan',
      price: 6000,
      imageUrl: 'assets/images/tahu_tempe.jpg',
      description: 'Lauk pendamping tahu dan tempe goreng tepung krispi',
    ),
    MenuItemData(
      id: '6',
      title: 'Telur Krispi',
      category: 'Tambahan',
      price: 5000,
      imageUrl: 'assets/images/telur_krispi.jpg',
      description: 'Telur dadar goreng tepung renyah',
    ),
    MenuItemData(
      id: '7',
      title: 'Jamur Krispi',
      category: 'Tambahan',
      price: 7000,
      imageUrl: 'assets/images/jamur_krispi.jpg',
      description: 'Jamur tiram goreng tepung gurih dan renyah',
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

  int get _grandTotal => _subtotal;


  void _showSambalPicker(OrderItem order, {int portionIndex = 0}) {
    order.syncPortions();
    final bool isMultiPortion = order.quantity > 1;
    final currentSambal = (portionIndex < order.sambalPerPortion.length)
        ? order.sambalPerPortion[portionIndex]
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'Pilih Varian Sambal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Menu: ${order.menuItem.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subTextGrey,
                  ),
                ),
                const SizedBox(height: 14),
                ...kSambalOptions.map((sambal) {
                  final isSelected = currentSambal == sambal;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (portionIndex < order.sambalPerPortion.length) {
                          order.sambalPerPortion[portionIndex] = sambal;
                        }
                      });
                      OrderStateService.setSambalChoices(
                        order.menuItem.title,
                        order.sambalPerPortion,
                      );
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('🌶️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Text(
                                sambal,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFFDC2626) : textDark,
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFFDC2626), size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (portionIndex < order.sambalPerPortion.length) {
                        order.sambalPerPortion[portionIndex] = null;
                      }
                    });
                    OrderStateService.setSambalChoices(
                      order.menuItem.title,
                      order.sambalPerPortion,
                    );
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentSambal == null ? const Color(0xFFF3F4F6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tanpa Sambal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subTextGrey,
                          ),
                        ),
                        if (currentSambal == null)
                          const Icon(Icons.check_rounded, color: subTextGrey, size: 20),
                      ],
                    ),
                  ),
                ),
                if (isMultiPortion) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          for (int k = 0; k < order.sambalPerPortion.length; k++) {
                            order.sambalPerPortion[k] = currentSambal;
                          }
                        });
                        OrderStateService.setSambalChoices(
                          order.menuItem.title,
                          order.sambalPerPortion,
                        );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.copy_all_rounded, size: 16, color: primaryGreen),
                      label: const Text(
                        'Samakan sambal ke semua item ini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog({int? bayar, int? kembalian, String? catatan}) async {
    setState(() {
      _isTransactionCompleted = true;
    });

    // Ambil kasir yang sedang bertugas dari widget/settings
    final savedKasir = await SettingsService.getLastKasir();
    final kasirName = (widget.currentKasir != null && widget.currentKasir!.isNotEmpty)
        ? widget.currentKasir!
        : (savedKasir ?? 'Rian');

    // Siapkan rincian item pesanan untuk database MariaDB (mendukung sambal berbeda per porsi)
    final List<Map<String, dynamic>> itemsPayload = [];
    for (var item in _orderedItems) {
      item.syncPortions();
      final Map<String?, int> sambalCounts = {};
      for (var s in item.sambalPerPortion) {
        sambalCounts[s] = (sambalCounts[s] ?? 0) + 1;
      }

      sambalCounts.forEach((sambalOpt, qty) {
        final map = <String, dynamic>{
          'productId': int.tryParse(item.menuItem.id),
          'name': item.menuItem.title,
          'category': item.menuItem.category,
          'price': item.menuItem.price,
          'quantity': qty,
          'subtotal': item.menuItem.price * qty,
        };
        if (sambalOpt != null && sambalOpt.trim().isNotEmpty) {
          map['sambal'] = sambalOpt.trim();
        }
        itemsPayload.add(map);
      });
    }

    final bool isQris = _paymentMethod.toUpperCase().contains('QRIS');
    final int cashReceivedVal = isQris ? _grandTotal : (bayar ?? _grandTotal);
    final int changeAmountVal = isQris
        ? 0
        : (kembalian ??
            (cashReceivedVal > _grandTotal ? cashReceivedVal - _grandTotal : 0));

    // Kirim pesanan ke backend MariaDB
    final apiResult = await ApiService.kirimPesanan(
      total: _grandTotal,
      paymentMethod: _paymentMethod,
      cashier: kasirName,
      cashReceived: cashReceivedVal,
      changeAmount: changeAmountVal,
      items: itemsPayload,
    );

    if (apiResult['success'] == true) {
      final dynamic savedData = apiResult['data'];
      final String rawTrxId =
          (savedData is Map ? savedData['id']?.toString() : null) ??
          'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final String receiptNumber =
          rawTrxId.startsWith('#') ? rawTrxId : '#$rawTrxId';

      await NotificationService.showPaymentSuccessNotification(
        receiptNumber: receiptNumber,
        paymentMethod: _paymentMethod,
        totalAmount: _grandTotal,
        cashReceived: cashReceivedVal,
        changeAmount: changeAmountVal,
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
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
            const SizedBox(height: 8),
            Text(
              _paymentMethod == 'Tunai' && bayar != null
                  ? 'Metode Pembayaran: Tunai\nTotal: ${_formatCurrency(_grandTotal)}\nBayar: ${_formatCurrency(bayar)}\nKembalian: ${_formatCurrency(kembalian ?? 0)}${catatan != null && catatan.isNotEmpty ? '\nCatatan: $catatan' : ''}\n\nStruk dicetak ke Thermal ESC/POS Printer'
                  : 'Metode Pembayaran: $_paymentMethod\nStruk dicetak ke Thermal ESC/POS Printer (${_formatCurrency(_grandTotal)})',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: subTextGrey, height: 1.4),
            ),
            if (apiResult['success'] != true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '⚠ ${apiResult['message'] ?? 'Koneksi ke server gagal'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                OrderStateService.clearOrder();
                setState(() {
                  _orderedItems.clear();
                });
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, true);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BerandaPage(
                        currentKasir: widget.currentKasir,
                        currentShift: widget.currentShift,
                      ),
                    ),
                  );
                }
              },
              child:
                  const Text('Selesai & Transaksi Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCashPaymentDialog() {
    final bayarController = TextEditingController();
    final kembalianController = TextEditingController();
    final cttController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateKembalian(String value) {
              final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (clean.isEmpty) {
                kembalianController.text = '';
                return;
              }
              final nominal = int.tryParse(clean) ?? 0;
              final diff = nominal - _grandTotal;
              if (diff >= 0) {
                kembalianController.text = _formatCurrency(diff);
              } else {
                kembalianController.text = 'Kurang ${_formatCurrency(diff.abs())}';
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: primaryGreen, width: 3.5),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Judul Dialog
                    const Text(
                      'Silahkan Masukan Nominal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Tagihan: ${_formatCurrency(_grandTotal)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input 1: bayar
                    TextField(
                      controller: bayarController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          updateKembalian(val);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'bayar',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2.8,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input 2: kembalian
                    TextField(
                      controller: kembalianController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryGreen,
                      ),
                      decoration: InputDecoration(
                        hintText: 'kembalian',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2.2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input 3: ctt
                    TextField(
                      controller: cttController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ctt',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 2.8,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol DONE
                    SizedBox(
                      width: 150,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final clean = bayarController.text.replaceAll(RegExp(r'[^0-9]'), '');
                          final bayarVal = int.tryParse(clean) ?? 0;

                          if (bayarVal < _grandTotal) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  bayarVal == 0
                                      ? 'Silakan masukkan uang bayar pembeli!'
                                      : 'Uang bayar kurang dari total ${_formatCurrency(_grandTotal)}',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          _showSuccessDialog(
                            bayar: bayarVal,
                            kembalian: bayarVal - _grandTotal,
                            catatan: cttController.text.trim(),
                          );
                        },
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                      _showSuccessDialog(
                        bayar: _grandTotal,
                        kembalian: 0,
                      );
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
      _showCashPaymentDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope<bool>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pop(context, _isTransactionCompleted);
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgYellow,
          endDrawer: AppDrawer(
            currentPage: 'transaksi',
            currentKasir: widget.currentKasir,
            currentShift: widget.currentShift,
          ),
          body: Stack(
            children: [
              // Background Decorative Graphics (Diagonal Orange Ribbons)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TransaksiBackgroundPainter(),
                ),
              ),

              Column(
                children: [
                  // 1. Header Bar (Putih memanjang sampai status bar)
                  _buildHeader(),

                  // 2. Scrollable Content
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pesanan Baru Title
                            _buildSubHeaderRow(),
                            const SizedBox(height: 14),

                            // Pesanan Card
                            _buildPesananCard(),
                            const SizedBox(height: 14),

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

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 8 : 12,
        bottom: 12,
        left: 18,
        right: 18,
      ),
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

  // --- Sub Header: Pesanan Baru & Tombol Kembali ---
  Widget _buildSubHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tombol Kembali ke Beranda (Atas Kiri)
        InkWell(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, _isTransactionCompleted);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BerandaPage(
                    currentKasir: widget.currentKasir,
                    currentShift: widget.currentShift,
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

        // PESANAN BARU Badge
        const Row(
          children: [
            Icon(Icons.circle, color: textDark, size: 8),
            SizedBox(width: 5),
            Text(
              'PESANAN BARU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
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
          if (_orderedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada menu yang dipilih',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subTextGrey,
                  ),
                ),
              ),
            )
          else
            // Ordered Items List
            ..._orderedItems.map((order) {
              order.syncPortions();
              final isMulti = order.quantity > 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title & Price
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
                          Text(
                            '@ ${_formatCurrency(order.menuItem.price)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subTextGrey,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Pilihan Sambal: Satuan atau Per-Porsi (Tampil Atas-Bawah)
                          if (!isMulti)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Sambal: ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: textDark,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _showSambalPicker(order, portionIndex: 0),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: order.sambalPerPortion[0] != null
                                            ? const Color(0xFFFEF2F2)
                                            : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: order.sambalPerPortion[0] != null
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            order.sambalPerPortion[0] != null
                                                ? '🌶️ ${order.sambalPerPortion[0]}'
                                                : '+ Pilih Sambal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: order.sambalPerPortion[0] != null
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 14,
                                            color: order.sambalPerPortion[0] != null
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Daftar Porsi untuk menu yang sama (disusun atas bawah per porsi)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(order.quantity, (pIndex) {
                                final pSambal = order.sambalPerPortion[pIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Sambal: ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showSambalPicker(order, portionIndex: pIndex),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: pSambal != null
                                                ? const Color(0xFFFEF2F2)
                                                : const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: pSambal != null
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFFE5E7EB),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                pSambal != null ? '🌶️ $pSambal' : '+ Pilih Sambal',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: pSambal != null
                                                      ? const Color(0xFFDC2626)
                                                      : const Color(0xFF6B7280),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_drop_down_rounded,
                                                size: 14,
                                                color: pSambal != null
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFF9CA3AF),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Quantity & Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            '${order.quantity}x',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'TOTAL PEMBAYARAN',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: 0.3,
            ),
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
    );
  }

  // --- Print & Save Button ---
  Widget _buildPrintButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
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
