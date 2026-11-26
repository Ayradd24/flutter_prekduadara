import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/order_state_service.dart';
import '../services/secure_storage_service.dart';
import '../services/settings_service.dart';
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
  final String? sambal;

  TransactionItemDetail({
    required this.name,
    required this.quantity,
    required this.price,
    this.sambal,
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
  final bool isToday;
  final bool isCurrentShift;
  final String? date;

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
    this.isToday = true,
    this.isCurrentShift = true,
    this.date,
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
  String _periodFilter = 'Saat Ini'; // 'Saat Ini' (pendapatan shift aktif) atau 'Hari Ini' (pendapatan hari itu)

  final Set<String> _expandedTrxIds = {};

  List<TransactionItem> _transactions = [];
  bool _isLoading = true;

  // Stats Saat Ini (shift aktif saat ini)
  int _shiftOmset = 0;
  int _shiftCount = 0;
  int _shiftTunaiOmset = 0;
  int _shiftTunaiCount = 0;
  int _shiftQrisOmset = 0;
  int _shiftQrisCount = 0;

  // Stats Hari Ini (seluruh transaksi hari itu)
  int _todayOmset = 0;
  int _todayCount = 0;
  int _todayTunaiOmset = 0;
  int _todayTunaiCount = 0;
  int _todayQrisOmset = 0;
  int _todayQrisCount = 0;

  int get _totalOmset => _periodFilter == 'Saat Ini' ? _shiftOmset : _todayOmset;
  int get _totalCount => _periodFilter == 'Saat Ini' ? _shiftCount : _todayCount;
  int get _tunaiOmset => _periodFilter == 'Saat Ini' ? _shiftTunaiOmset : _todayTunaiOmset;
  int get _tunaiCount => _periodFilter == 'Saat Ini' ? _shiftTunaiCount : _todayTunaiCount;
  int get _qrisOmset => _periodFilter == 'Saat Ini' ? _shiftQrisOmset : _todayQrisOmset;
  int get _qrisCount => _periodFilter == 'Saat Ini' ? _shiftQrisCount : _todayQrisCount;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    SettingsService.getLastKasir().then((k) {
      if (k != null && mounted) setState(() => _savedKasir = k);
    });
    _fetchTransactions();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchTransactions();
        _checkActiveSession();
      }
    });
  }

  bool _isAutoRedirecting = false;
  int _sessionCheckTicks = 0;

  /// Cek berkala apakah sesi kasir di perangkat ini telah ditutup dari device lain atau web
  Future<void> _checkActiveSession() async {
    if (_isAutoRedirecting || !mounted) return;
    _sessionCheckTicks++;
    if (_sessionCheckTicks < 2) return;

    final isActive = await ApiService.isKasirActive(_effectiveKasir);
    if (!isActive && mounted && !_isAutoRedirecting) {
      _isAutoRedirecting = true;
      _refreshTimer?.cancel();
      OrderStateService.clearOrder();
      await SecureStorageService().deleteAuthToken();
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shift $_effectiveKasir telah ditutup dari perangkat lain.',
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    if (_transactions.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await ApiService.ambilRiwayatTransaksi();
      int sOmset = 0;
      int sCount = 0;
      int sTunai = 0;
      int sTunaiC = 0;
      int sQris = 0;
      int sQrisC = 0;

      int tOmset = 0;
      int tCount = 0;
      int tTunai = 0;
      int tTunaiC = 0;
      int tQris = 0;
      int tQrisC = 0;

      List<TransactionItem> parsedList = [];
      for (var tx in list) {
        if (tx is Map) {
          final isTxToday = OmsetSummary.isToday(tx['created_at']);
          final txCashier = tx['cashier']?.toString();

          bool isTxCurrentShift = false;
          if (isTxToday) {
            if (OmsetSummary.isCashierMatch(txCashier, _namaKasir)) {
              isTxCurrentShift = true;
            } else if (OmsetSummary.isDifferentCashier(txCashier, _namaKasir)) {
              isTxCurrentShift = false;
            } else {
              final txShift = OmsetSummary.getShiftName(
                tx['created_at'],
                timeStr: tx['time']?.toString(),
                cashier: txCashier,
              );
              isTxCurrentShift = OmsetSummary.isShiftMatch(txShift, _effectiveShift);
            }
          }

          final amount = int.tryParse(tx['total']?.toString() ?? '0') ?? 0;
          final rawMethod = (tx['paymentMethod'] ?? 'TUNAI').toString().toUpperCase();
          final method = rawMethod.contains('QRIS') ? 'QRIS' : 'TUNAI';

          // Akumulasi Hari Ini (semua transaksi hari itu)
          if (isTxToday) {
            tOmset += amount;
            tCount++;
            if (method == 'TUNAI') {
              tTunai += amount;
              tTunaiC++;
            } else {
              tQris += amount;
              tQrisC++;
            }
          }

          // Akumulasi Saat Ini (khusus shift aktif saat ini)
          if (isTxCurrentShift) {
            sOmset += amount;
            sCount++;
            if (method == 'TUNAI') {
              sTunai += amount;
              sTunaiC++;
            } else {
              sQris += amount;
              sQrisC++;
            }
          }

          // Parse details
          List<TransactionItemDetail> details = [];
          final rawItems = tx['items'];
          if (rawItems is List) {
            for (var it in rawItems) {
              if (it is Map) {
                details.add(TransactionItemDetail(
                  name: it['name']?.toString() ?? 'Menu',
                  quantity: int.tryParse(it['quantity']?.toString() ?? '1') ?? 1,
                  price: int.tryParse(it['price']?.toString() ?? '0') ?? 0,
                  sambal: it['sambal']?.toString(),
                ));
              }
            }
          } else if (rawItems is String) {
            try {
              final decoded = jsonDecode(rawItems);
              if (decoded is List) {
                for (var it in decoded) {
                  if (it is Map) {
                    details.add(TransactionItemDetail(
                      name: it['name']?.toString() ?? 'Menu',
                      quantity: int.tryParse(it['quantity']?.toString() ?? '1') ?? 1,
                      price: int.tryParse(it['price']?.toString() ?? '0') ?? 0,
                      sambal: it['sambal']?.toString(),
                    ));
                  }
                }
              }
            } catch (_) {}
          }

          if (details.isEmpty) {
            details.add(TransactionItemDetail(
              name: tx['itemsSummary']?.toString() ?? 'Ayam Geprek + Es Teh',
              quantity: int.tryParse(tx['totalItems']?.toString() ?? '1') ?? 1,
              price: amount,
            ));
          }

          final rawId = tx['id']?.toString() ?? 'TRX-???';
          final id = rawId.startsWith('#') ? rawId : '#$rawId';
          final cashierName = tx['cashier']?.toString() ?? _namaKasir;

          // Format tanggal transaksi
          String? dateStr;
          if (tx['created_at'] != null) {
            final dt = DateTime.tryParse(tx['created_at'].toString())?.toLocal();
            if (dt != null) {
              dateStr = '${dt.day}/${dt.month}/${dt.year}';
            }
          }

          int? parseOptionalInt(dynamic raw) {
            if (raw == null) return null;
            if (raw is int) return raw;
            if (raw is num) return raw.toInt();
            return int.tryParse(raw.toString());
          }

          final int? rawCashReceived =
              parseOptionalInt(tx['cash_received']) ??
              parseOptionalInt(tx['amount_paid']) ??
              parseOptionalInt(tx['cashReceived']) ??
              parseOptionalInt(tx['amountPaid']);
          final int? rawChangeAmount =
              parseOptionalInt(tx['change_amount']) ??
              parseOptionalInt(tx['changeAmount']) ??
              parseOptionalInt(tx['change']);

          final int cashReceivedVal =
              method == 'QRIS' ? amount : (rawCashReceived ?? amount);
          final int changeVal = method == 'QRIS'
              ? 0
              : (rawChangeAmount ??
                  (cashReceivedVal > amount ? cashReceivedVal - amount : 0));

          parsedList.add(TransactionItem(
            id: id,
            time: tx['time']?.toString() ?? '12:00',
            status: 'LUNAS',
            items: tx['itemsSummary']?.toString() ?? 'Pesanan PrekDuaDara',
            paymentMethod: method,
            cashier: 'Kasir: $cashierName',
            totalAmount: amount,
            subtotal: amount,
            tax: 0,
            cashReceived: cashReceivedVal,
            change: changeVal,
            details: details,
            isToday: isTxToday,
            isCurrentShift: isTxCurrentShift,
            date: dateStr,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _transactions = parsedList;
          _shiftOmset = sOmset;
          _shiftCount = sCount;
          _shiftTunaiOmset = sTunai;
          _shiftTunaiCount = sTunaiC;
          _shiftQrisOmset = sQris;
          _shiftQrisCount = sQrisC;

          _todayOmset = tOmset;
          _todayCount = tCount;
          _todayTunaiOmset = tTunai;
          _todayTunaiCount = tTunaiC;
          _todayQrisOmset = tQris;
          _todayQrisCount = tQrisC;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch transactions in LogTransaksi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _savedKasir;

  String get _effectiveKasir {
    if (widget.currentKasir != null &&
        widget.currentKasir!.isNotEmpty &&
        widget.currentKasir != 'Pilih Kasir') {
      return widget.currentKasir!;
    }
    if (_savedKasir != null && _savedKasir!.isNotEmpty) {
      return _savedKasir!;
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

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _handleReprintReceipt(TransactionItem trx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        title: Column(
          children: [
            const Text(
              'PREK DUA DARA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Struk ${trx.id} • ${trx.date ?? ''} ${trx.time}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: subTextGrey,
              ),
            ),
            Text(
              trx.cashier,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: subTextGrey,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 16, thickness: 1, color: Color(0xFFE5E7EB)),
              ...trx.details.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          d.sambal != null && d.sambal!.trim().isNotEmpty
                              ? '${d.quantity}x ${d.name} (${d.sambal})'
                              : '${d.quantity}x ${d.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCurrency(d.price * d.quantity),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16, thickness: 1, color: Color(0xFFE5E7EB)),
              _buildDetailRow(
                label: 'TOTAL BAYAR',
                value: _formatCurrency(trx.totalAmount),
                isBold: true,
              ),
              const SizedBox(height: 6),
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
                  value: 'QRIS (${_formatCurrency(trx.cashReceived)})',
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  label: 'Kembalian',
                  value: _formatCurrency(0),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: subTextGrey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          trx.paymentMethod == 'TUNAI'
                              ? 'Struk ${trx.id} dicetak (Tunai: ${_formatCurrency(trx.cashReceived)}, Kembali: ${_formatCurrency(trx.change)})'
                              : 'Struk ${trx.id} dicetak (QRIS: ${_formatCurrency(trx.totalAmount)})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 17),
            label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleCloseShift() {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    bool isClosing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
              onPressed: isClosing ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: subTextGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isClosing
                  ? null
                  : () async {
                      setDialogState(() => isClosing = true);
                      OrderStateService.clearOrder();
                      // Sinkronkan status kasir menjadi Standby di backend MariaDB
                      final synced = await ApiService.logoutKasir(_effectiveKasir);
                      // Hapus sesi kasir aktif secara aman
                      await SecureStorageService().deleteAuthToken();

                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            synced
                                ? 'Shift berhasil ditutup!'
                                : 'Shift ditutup (gagal sinkron ke server, cek koneksi)',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: synced
                              ? primaryGreen
                              : const Color(0xFFD97706),
                        ),
                      );
                    },
              child: isClosing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Tutup Shift', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodList = _periodFilter == 'Saat Ini'
        ? _transactions.where((t) => t.isCurrentShift).toList()
        : _transactions.where((t) => t.isToday).toList();

    final filteredList = _selectedFilter == 'Semua'
        ? periodList
        : periodList
            .where((t) => t.paymentMethod.toUpperCase() == _selectedFilter.toUpperCase())
            .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
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

            Column(
              children: [
                // 1. Header Bar (Putih memanjang sampai status bar)
                _buildHeader(),

                // 2. Scrollable Content
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: RefreshIndicator(
                      onRefresh: _fetchTransactions,
                      color: primaryGreen,
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
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

                            // Transactions List / Loading / Empty
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: primaryGreen,
                                  ),
                                ),
                              )
                            else if (filteredList.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Belum ada transaksi',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedFilter == 'Semua'
                                          ? (_periodFilter == 'Saat Ini'
                                              ? 'Belum ada transaksi pada shift ini ($_effectiveShift)'
                                              : 'Belum ada transaksi hari ini')
                                          : 'Tidak ada transaksi dengan metode $_selectedFilter',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, color: subTextGrey),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...filteredList.map((trx) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildTransactionCard(trx),
                                  )),

                            const SizedBox(height: 12),

                            // Validasi Akhir Shift Section
                            _buildValidasiShiftSection(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  Widget _buildPeriodTab(String label, IconData icon, int count) {
    final isSelected = _periodFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _periodFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : textDark,
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pesanan Harian Row ---
  Widget _buildPesananHarianRow() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _periodFilter == 'Saat Ini' ? 'Pesanan Shift Saat Ini' : 'Pesanan Hari Ini',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textDark,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: textDark),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPeriodTab('Saat Ini', Icons.access_time_rounded, _shiftCount),
            const SizedBox(width: 8),
            _buildPeriodTab('Hari Ini', Icons.calendar_today_rounded, _todayCount),
          ],
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
              Row(
                children: [
                  const Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: 19,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _periodFilter == 'Saat Ini' ? 'Omset Shift Saat Ini' : 'Total Omset Hari Ini',
                    style: const TextStyle(
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
                  _periodFilter == 'Saat Ini' ? _effectiveShift : 'Hari Ini',
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
          Text(
            _isLoading ? 'Memuat...' : _formatCurrency(_totalOmset),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Status Row
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 15,
                color: Color(0xFF4B5563),
              ),
              const SizedBox(width: 5),
              Text(
                '$_totalCount Transaksi Selesai',
                style: const TextStyle(
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
                  if (_tunaiOmset > 0 || _totalOmset == 0)
                    Expanded(
                      flex: _tunaiOmset > 0 ? _tunaiOmset : 1,
                      child: Container(color: primaryGreen),
                    ),
                  if (_tunaiOmset > 0 && _qrisOmset > 0)
                    const SizedBox(width: 2),
                  if (_qrisOmset > 0 || (_totalOmset == 0 && _tunaiOmset == 0))
                    Expanded(
                      flex: _qrisOmset > 0 ? _qrisOmset : 1,
                      child: Container(color: qrisBlue),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 7, color: primaryGreen),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tunai: ${_formatCurrency(_tunaiOmset)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$_tunaiCount Transaksi',
                        style: const TextStyle(
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
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 7, color: qrisBlue),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QRIS: ${_formatCurrency(_qrisOmset)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: qrisBlue,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$_qrisCount Transaksi',
                        style: const TextStyle(
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
      {'label': 'Semua ($_totalCount)', 'key': 'Semua'},
      {'label': 'Tunai ($_tunaiCount)', 'key': 'Tunai'},
      {'label': 'QRIS ($_qrisCount)', 'key': 'QRIS'},
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
                          trx.isToday || trx.date == null
                              ? trx.time
                              : '${trx.date} • ${trx.time}',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ${detail.quantity}x ${detail.name}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textDark,
                                    ),
                                  ),
                                  if (detail.sambal != null &&
                                      detail.sambal!.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10, top: 2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: const Color(0xFFFECACA)),
                                        ),
                                        child: Text(
                                          '🌶️ ${detail.sambal}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
