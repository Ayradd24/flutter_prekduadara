import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/order_state_service.dart';
import '../services/secure_storage_service.dart';
import '../services/settings_service.dart';
import '../widget/app_drawer.dart';
import 'Login.dart';
import 'Transaksi.dart';
import 'LogTransaksi.dart';

// Palette warna konsisten tema PrekDuaDara
const Color bgYellow = Color(0xFFFBBF24);
const Color primaryGreen = Color(0xFF1E6F38);
const Color ribbonOrange = Color(0xFFE57E25);
const Color textDark = Color(0xFF111111);
const Color subTextGrey = Color(0xFF6B7280);
const Color qrisBlue = Color(0xFF2563EB);

class ProductMenuItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String imageUrl;

  ProductMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}

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

  String? _currentKasir;
  String? _currentShift;

  int _totalOmset = 0;
  int _totalCount = 0;
  int _tunaiOmset = 0;
  int _tunaiCount = 0;
  int _qrisOmset = 0;
  int _qrisCount = 0;
  bool _isLoadingOmset = true;
  Timer? _omsetTimer;

  static final List<ProductMenuItem> _defaultProducts = [
    ProductMenuItem(
      id: '1',
      name: 'Ayam Geprek Bakar + Es Teh',
      description: 'Nasi + Ayam Geprek Bakar + Es Teh',
      price: 18000,
      category: 'Paket Menu',
      imageUrl: 'assets/images/geprek_bakar.jpg',
    ),
    ProductMenuItem(
      id: '2',
      name: 'Ayam Geprek Biasa + Es Teh',
      description: 'Nasi + Ayam Geprek Biasa + Es Teh',
      price: 17000,
      category: 'Paket Menu',
      imageUrl: 'assets/images/geprek_biasa.jpg',
    ),
    ProductMenuItem(
      id: '3',
      name: 'Ayam Geprek Mozzarella + Es Teh',
      description: 'Paket ayam geprek krispi dengan lelehan keju mozzarella, nasi & es teh sepuasnya',
      price: 22000,
      category: 'Paket Menu',
      imageUrl: 'assets/images/geprek_mozzarella.jpg',
    ),
    ProductMenuItem(
      id: '4',
      name: 'Ayam Geprek (Tanpa Nasi)',
      description: 'Potongan ayam geprek krispi tanpa nasi',
      price: 13000,
      category: 'Tambahan',
      imageUrl: 'assets/images/geprek_tanpa_nasi.jpg',
    ),
    ProductMenuItem(
      id: '5',
      name: 'Tahu & Tempe Geprek',
      description: 'Lauk pendamping tahu dan tempe goreng tepung krispi',
      price: 6000,
      category: 'Tambahan',
      imageUrl: 'assets/images/tahu_tempe.jpg',
    ),
    ProductMenuItem(
      id: '6',
      name: 'Telur Krispi',
      description: 'Telur dadar goreng tepung renyah',
      price: 5000,
      category: 'Tambahan',
      imageUrl: 'assets/images/telur_krispi.jpg',
    ),
    ProductMenuItem(
      id: '7',
      name: 'Jamur Krispi',
      description: 'Jamur tiram goreng tepung gurih dan renyah',
      price: 7000,
      category: 'Tambahan',
      imageUrl: 'assets/images/jamur_krispi.jpg',
    ),
  ];

  late List<ProductMenuItem> _menuProducts;
  String _selectedCategoryFilter = 'Semua';

  String get _effectiveKasir {
    if (_currentKasir != null && _currentKasir!.isNotEmpty && _currentKasir != 'Pilih Kasir') {
      return _currentKasir!;
    }
    if (widget.currentKasir != null && widget.currentKasir!.isNotEmpty && widget.currentKasir != 'Pilih Kasir') {
      return widget.currentKasir!;
    }
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 12) return 'Rian';
    if (hour >= 12 && hour < 17) return 'Siti';
    return 'Budi';
  }

  String get _effectiveShift {
    if (_currentShift != null && _currentShift!.isNotEmpty && _currentShift != '-') {
      return _currentShift!;
    }
    if (widget.currentShift != null && widget.currentShift!.isNotEmpty && widget.currentShift != '-') {
      return widget.currentShift!;
    }
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 12) return 'Shift Pagi';
    if (hour >= 12 && hour < 17) return 'Shift Siang';
    return 'Shift Malam';
  }

  // Map of item quantities added
  final Map<String, int> _itemCounts = {};

  // Cek apakah ada pesanan yang sedang dipilih
  bool get _hasOrder => _itemCounts.values.any((count) => count > 0);

  @override
  void initState() {
    super.initState();
    _menuProducts = List.from(_defaultProducts);
    for (var p in _menuProducts) {
      _itemCounts[p.name] = OrderStateService.getItemCount(p.name);
    }
    for (var entry in OrderStateService.itemCounts.entries) {
      _itemCounts[entry.key] = entry.value;
    }
    _currentKasir = widget.currentKasir;
    _currentShift = widget.currentShift;
    if (_currentKasir == null) {
      SettingsService.getLastKasir().then((saved) {
        if (saved != null && saved.isNotEmpty && mounted) {
          setState(() {
            _currentKasir = saved;
          });
          _fetchOmsetData();
        }
      });
    }
    _loadProductsFromDatabase();
    _loadCashiers();
    _fetchOmsetData();
    _omsetTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchOmsetData();
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
      _omsetTimer?.cancel();
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

  /// Sinkronisasi daftar staf kasir langsung dari backend MariaDB
  Future<void> _loadCashiers() async {
    try {
      final list = await ApiService.ambilDaftarKasir();
      if (list.isNotEmpty && mounted) {
        // Sinkronkan nama kasir aktif hanya jika benar-benar cocok di database
        final current = _effectiveKasir.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
        KasirModel? matched;
        for (final c in list) {
          if (c.shortName.toLowerCase() == current.toLowerCase() ||
              c.name.toLowerCase() == current.toLowerCase()) {
            matched = c;
            break;
          }
        }

        if (matched != null && matched.name != current && matched.shortName != current) {
          setState(() {
            _currentKasir = matched!.name;
          });
          await SettingsService.setLastKasir(matched.name);
        }
      }
    } catch (e) {
      debugPrint('Error loading cashiers in Beranda: $e');
    }
  }

  @override
  void dispose() {
    _omsetTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOmsetData() async {
    try {
      final summary = await ApiService.ambilOmsetSummary(
        shift: _effectiveShift,
        cashier: _effectiveKasir,
      );
      if (mounted) {
        if (_totalOmset != summary.totalOmset ||
            _totalCount != summary.totalCount ||
            _tunaiOmset != summary.tunaiOmset ||
            _qrisOmset != summary.qrisOmset ||
            _isLoadingOmset) {
          setState(() {
            _totalOmset = summary.totalOmset;
            _totalCount = summary.totalCount;
            _tunaiOmset = summary.tunaiOmset;
            _tunaiCount = summary.tunaiCount;
            _qrisOmset = summary.qrisOmset;
            _qrisCount = summary.qrisCount;
            _isLoadingOmset = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching omset in Beranda: $e');
      if (mounted) {
        setState(() {
          _isLoadingOmset = false;
        });
      }
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  Future<void> _loadProductsFromDatabase() async {
    try {
      // 1. Ambil dari endpoint publik backend MariaDB (/api/products)
      final apiProducts = await ApiService.ambilDaftarProduk();
      if (mounted && apiProducts.isNotEmpty) {
        setState(() {
          _menuProducts = apiProducts.map((p) {
            final name = p['name']?.toString() ?? '';
            String img = p['image']?.toString() ?? '';
            if (img.trim().isEmpty) {
              final lower = name.toLowerCase();
              if (lower.contains('bakar')) {
                img = 'assets/images/geprek_bakar.jpg';
              } else if (lower.contains('mozzarella')) {
                img = 'assets/images/geprek_mozzarella.jpg';
              } else if (lower.contains('tanpa nasi')) {
                img = 'assets/images/geprek_tanpa_nasi.jpg';
              } else if (lower.contains('biasa')) {
                img = 'assets/images/geprek_biasa.jpg';
              } else if (lower.contains('tahu')) {
                img = 'assets/images/tahu_tempe.jpg';
              } else if (lower.contains('telur')) {
                img = 'assets/images/telur_krispi.jpg';
              } else if (lower.contains('jamur')) {
                img = 'assets/images/jamur_krispi.jpg';
              }
            }
            return ProductMenuItem(
              id: p['id']?.toString() ?? '',
              name: name,
              description: p['description']?.toString() ?? '',
              price: int.tryParse(p['price']?.toString() ?? '0') ?? 0,
              category: p['category']?.toString() ?? 'Paket Menu',
              imageUrl: img,
            );
          }).toList();
          for (var p in _menuProducts) {
            _itemCounts[p.name] = OrderStateService.getItemCount(p.name);
          }
        });
        return;
      }

      // 2. Fallback: baca dari local SQLite Drift
      final dbProducts = await AppDatabase.instance.getAllProducts();
      if (mounted && dbProducts.isNotEmpty) {
        setState(() {
          for (var p in dbProducts) {
            _itemCounts[p.name] = OrderStateService.getItemCount(p.name);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _addItem(String name, int price) {
    OrderStateService.addItem(name);
    setState(() {
      _itemCounts[name] = OrderStateService.getItemCount(name);
    });
  }

  void _removeItem(String name) {
    OrderStateService.removeItem(name);
    setState(() {
      _itemCounts[name] = OrderStateService.getItemCount(name);
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

            Column(
              children: [
                // 1. Top Bar / Header (Putih memanjang sampai menutupi status bar)
                _buildHeader(),

                // 2. Main Scrollable Content
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _fetchOmsetData();
                        await _loadProductsFromDatabase();
                      },
                      color: primaryGreen,
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          _hasOrder ? 100 : 24,
                        ),
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
                            const SizedBox(height: 12),

                            // Daftar Menu Produk Dinamis (7 Menu)
                            ..._menuProducts
                                .where((p) =>
                                    _selectedCategoryFilter == 'Semua' ||
                                    p.category == _selectedCategoryFilter)
                                .map((p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildMenuItemCard(
                                        title: p.name,
                                        description: p.description,
                                        price: p.price,
                                        imageUrl: p.imageUrl,
                                        category: p.category,
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tombol Konfirmasi dan Bayar Melayang (Floating di Bawah Layar Saat Ada Pesanan)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              bottom: _hasOrder ? 16 : -110,
              child: SafeArea(
                top: false,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _hasOrder ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_hasOrder,
                    child: _buildConfirmPayButton(),
                  ),
                ),
              ),
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
          Text(
            _isLoadingOmset ? 'Memuat...' : _formatCurrency(_totalOmset),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Completed Transactions Count
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

          // Dual-segment Progress Bar (Green + Blue)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  // Tunai Segment (Green)
                  if (_tunaiOmset > 0 || _totalOmset == 0)
                    Expanded(
                      flex: _tunaiOmset > 0 ? _tunaiOmset : 1,
                      child: Container(color: primaryGreen),
                    ),
                  if (_tunaiOmset > 0 && _qrisOmset > 0)
                    const SizedBox(width: 2),
                  // QRIS Segment (Blue)
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
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogTransaksiPage(
                      currentKasir: _effectiveKasir,
                      currentShift: _effectiveShift,
                    ),
                  ),
                );
                if (mounted) _fetchOmsetData();
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
        const SizedBox(height: 10),
        // Filter Kategori (Semua, Paket Menu, Tambahan)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Semua', 'Paket Menu', 'Tambahan'].map((cat) {
              final isSel = _selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryFilter = cat;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? primaryGreen : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? Colors.white : textDark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
    String? category,
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
              child: imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 32,
                      ),
                    )
                  : imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                          cacheHeight: 160,
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
                          cacheWidth: 160,
                          cacheHeight: 160,
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
                if (category != null && category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: category == 'Paket Menu'
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: category == 'Paket Menu'
                              ? const Color(0xFF92400E)
                              : const Color(0xFF3730A3),
                        ),
                      ),
                    ),
                  ),
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
    for (var product in _menuProducts) {
      final count = _itemCounts[product.name] ?? 0;
      totalPrice += count * product.price;
    }

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
                currentKasir: _effectiveKasir,
                currentShift: _effectiveShift,
              ),
            ),
          );

          if (mounted) {
            _fetchOmsetData();
            if (result == true) {
              OrderStateService.clearOrder();
              setState(() {
                _itemCounts.updateAll((key, value) => 0);
              });
            } else {
              setState(() {
                for (var p in _menuProducts) {
                  _itemCounts[p.name] = OrderStateService.getItemCount(p.name);
                }
              });
            }
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
