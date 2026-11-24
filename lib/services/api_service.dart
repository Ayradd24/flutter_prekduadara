import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Daftar kandidat endpoint backend statis:
  // 1. 127.0.0.1:5000 (Untuk USB adb reverse HP fisik Android, Windows Desktop, dan Chrome - bebas DNS lookup error)
  // 2. IP Wi-Fi Laptop aktif (untuk koneksi HP nirkabel / tanpa kabel USB)
  // 3. localhost:5000
  // 4. 10.0.2.2:5000 (Untuk Android Emulator)
  static final List<String> _staticCandidates = [
    'http://127.0.0.1:5000/api',
    'http://10.200.178.25:5000/api',
    'http://10.112.21.148:5000/api',
    'http://10.196.72.148:5000/api',
    'http://10.0.2.2:5000/api',
    'http://localhost:5000/api',
  ];

  static String? _workingBaseUrl;

  /// Resolusikan URL gambar (jika relatif seperti /uploads/products/xxx) ke URL absolut aktif
  static String resolveImageUrl(String? rawUrl, [String? activeBaseUrl]) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();
    if (url.startsWith('assets/') ||
        url.startsWith('http://') ||
        url.startsWith('https://')) {
      return url;
    }
    final base = activeBaseUrl ?? baseUrl;
    final origin = base.replaceAll(RegExp(r'/api/?$'), '');
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$origin$cleanPath';
  }

  /// Dapatkan base URL yang aktif.
  /// Otomatis mendeteksi IP backend di jaringan Wi-Fi manapun.
  static Future<String> getBaseUrl() async {
    // 1. Cek apakah URL yang di-cache masih aktif
    if (_workingBaseUrl != null) {
      try {
        final res = await http
            .get(Uri.parse('$_workingBaseUrl/transactions'))
            .timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) return _workingBaseUrl!;
      } catch (_) {
        debugPrint('⚠️ Cached URL $_workingBaseUrl tidak responsif, mencari ulang...');
        _workingBaseUrl = null;
      }
    }

    // 2. Coba kandidat statis (localhost / emulator)
    for (final candidate in _staticCandidates) {
      try {
        final res = await http
            .get(Uri.parse('$candidate/transactions'))
            .timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) {
          _workingBaseUrl = candidate;
          debugPrint('✅ ApiService terhubung ke: $candidate');
          return candidate;
        }
      } catch (_) {}
    }

    // 3. Auto-discovery: scan subnet Wi-Fi untuk menemukan backend
    final discovered = await _discoverBackendOnSubnet();
    if (discovered != null) {
      _workingBaseUrl = discovered;
      debugPrint('✅ ApiService auto-discovered backend: $discovered');
      return discovered;
    }

    debugPrint('❌ Tidak dapat menemukan backend di jaringan manapun');
    return _staticCandidates.first;
  }

  static String get baseUrl => _workingBaseUrl ?? _staticCandidates.first;

  /// Reset cache URL agar discovery dijalankan ulang (panggil saat ganti Wi-Fi)
  static void resetConnection() {
    _workingBaseUrl = null;
    debugPrint('🔄 Koneksi backend di-reset, akan auto-discover saat request berikutnya');
  }

  /// Scan seluruh subnet Wi-Fi untuk menemukan server backend pada port 5000.
  /// Menggunakan TCP port scan paralel (cepat, ~300ms) lalu verifikasi HTTP.
  static Future<String?> _discoverBackendOnSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      final Set<String> subnets = {};
      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('127.')) continue; // Skip loopback
          final parts = ip.split('.');
          if (parts.length == 4) {
            subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }

      if (subnets.isEmpty) return null;

      debugPrint('🔍 Scanning ${subnets.length} subnet(s) untuk backend: $subnets');

      for (var subnet in subnets) {
        // Scan port 5000 pada semua 254 host secara paralel
        final futures = <Future<String?>>[];
        for (int i = 1; i <= 254; i++) {
          futures.add(_checkPort('$subnet.$i', 5000));
        }

        final results = await Future.wait(futures);
        final openHosts = results.where((ip) => ip != null).toList();

        debugPrint('🔍 Subnet $subnet.* → ${openHosts.length} host dengan port 5000 terbuka');

        // Verifikasi mana yang benar-benar backend PrekDuaDara
        for (var ip in openHosts) {
          if (ip == null) continue;
          final url = 'http://$ip:5000/api';
          try {
            final res = await http
                .get(Uri.parse('$url/transactions'))
                .timeout(const Duration(milliseconds: 1500));
            if (res.statusCode == 200) {
              return url;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('⚠️ Subnet discovery error: $e');
    }
    return null;
  }

  /// Cek apakah sebuah IP membuka port tertentu (TCP connect test)
  static Future<String?> _checkPort(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 400),
      );
      socket.destroy();
      return ip;
    } catch (_) {
      return null;
    }
  }

  /// Kirim transaksi pemesanan baru ke database MariaDB
  static Future<Map<String, dynamic>> kirimPesanan({
    required int total,
    required String paymentMethod,
    String? cashier,
    required List<Map<String, dynamic>> items,
    int? cashReceived,
    int? changeAmount,
  }) async {
    final activeBase = await getBaseUrl();

    String lastError = 'Koneksi ke backend gagal';

    try {
      final url = Uri.parse('$activeBase/transactions');
      final Map<String, dynamic> bodyMap = {
        'total': total,
        'paymentMethod': paymentMethod,
        'cashier': cashier ?? 'Kasir Prek Dua Dara',
        'items': items,
      };
      if (cashReceived != null) {
        bodyMap['cashReceived'] = cashReceived;
      }
      if (changeAmount != null) {
        bodyMap['changeAmount'] = changeAmount;
      }
      final payload = jsonEncode(bodyMap);

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Berhasil kirim pesanan via $activeBase');
        return {
          'success': true,
          'message': data['message'] ?? 'Transaksi berhasil disimpan ke MariaDB',
          'data': data['data'],
          'activeUrl': activeBase,
        };
      } else {
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      lastError = '$e';
      debugPrint('Gagal kirim pesanan via $activeBase: $e');
      // Reset agar discovery ulang di request berikutnya
      _workingBaseUrl = null;
    }

    return {
      'success': false,
      'message': 'Gagal menyimpan transaksi: $lastError',
    };
  }

  /// Ambil seluruh riwayat transaksi dari backend MariaDB
  static Future<List<dynamic>> ambilRiwayatTransaksi() async {
    final activeBase = await getBaseUrl();

    try {
      final url = Uri.parse('$activeBase/transactions');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          debugPrint('✅ Ambil transaksi sukses dari $activeBase: ${(json['data'] as List).length} item');
          return json['data'];
        }
      }
    } catch (e) {
      debugPrint('Gagal ambil riwayat dari $activeBase: $e');
      _workingBaseUrl = null;
    }

    return [];
  }

  /// Ambil seluruh daftar produk resmi dari endpoint publik backend MariaDB (/api/products)
  static Future<List<Map<String, dynamic>>> ambilDaftarProduk() async {
    final activeBase = await getBaseUrl();

    try {
      final url = Uri.parse('$activeBase/products');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          debugPrint('✅ Ambil produk sukses dari $activeBase: ${(json['data'] as List).length} menu');
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (e) {
      debugPrint('Gagal ambil daftar produk dari $activeBase: $e');
    }

    return [];
  }

  /// Ambil ringkasan omset shift dari database MariaDB (secara default hanya hari ini)
  static Future<OmsetSummary> ambilOmsetSummary({
    bool todayOnly = true,
    String? shift,
    String? cashier,
  }) async {
    final list = await ambilRiwayatTransaksi();
    return OmsetSummary.fromTransactions(
      list,
      todayOnly: todayOnly,
      shift: shift,
      cashier: cashier,
    );
  }

  /// Ambil daftar staf kasir dari database MariaDB
  static Future<List<KasirModel>> ambilDaftarKasir() async {
    final activeBase = await getBaseUrl();

    try {
      final url = Uri.parse('$activeBase/cashiers');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          final list = (json['data'] as List)
              .map((item) => KasirModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('Gagal ambil daftar kasir: $e');
      _workingBaseUrl = null;
    }

    return [];
  }

  /// Perbarui nama kasir di database MariaDB (sinkron dengan web)
  static Future<Map<String, dynamic>> updateNamaKasir({
    required String idOrCode,
    required String newName,
    String? shift,
  }) async {
    final activeBase = await getBaseUrl();

    try {
      final encodedId = Uri.encodeComponent(idOrCode);
      final url = Uri.parse('$activeBase/cashiers/$encodedId');
      final Map<String, dynamic> bodyData = {'name': newName.trim()};
      if (shift != null) bodyData['shift'] = shift;
      final payload = jsonEncode(bodyData);

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'message': json['message'] ?? 'Nama kasir berhasil diperbarui',
          'data': json['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('Gagal update nama kasir: $e');
      _workingBaseUrl = null;
      return {
        'success': false,
        'message': 'Gagal memperbarui nama kasir: $e',
      };
    }
  }

  /// Tambah staf kasir baru ke database MariaDB
  static Future<Map<String, dynamic>> tambahKasir({
    required String name,
    required String shift,
  }) async {
    final activeBase = await getBaseUrl();

    try {
      final url = Uri.parse('$activeBase/cashiers');
      final payload = jsonEncode({
        'name': name.trim(),
        'shift': shift,
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'message': json['message'] ?? 'Kasir baru berhasil didaftarkan',
          'data': json['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('Gagal tambah kasir: $e');
      _workingBaseUrl = null;
      return {
        'success': false,
        'message': 'Gagal menambahkan kasir: $e',
      };
    }
  }

  /// Tandai kasir sedang aktif melayani (login shift) di backend MariaDB
  static Future<bool> loginKasir(String cashierNameOrId) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      final activeBase = await getBaseUrl();
      try {
        final url = Uri.parse('$activeBase/cashiers/login');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'cashier': cashierNameOrId}),
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          debugPrint('✅ Kasir $cashierNameOrId berhasil login aktif di backend MariaDB ($activeBase)');
          return true;
        }
        debugPrint('⚠️ loginKasir HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        debugPrint('⚠️ Gagal login kasir (attempt ${attempt + 1}) via $activeBase: $e');
      }
      _workingBaseUrl = null;
    }
    return false;
  }

  /// Tandai kasir selesai shift / standby di backend MariaDB
  static Future<bool> logoutKasir([String? cashierNameOrId]) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      final activeBase = await getBaseUrl();
      try {
        final url = Uri.parse('$activeBase/cashiers/logout');
        final bodyData = cashierNameOrId != null
            ? {'cashier': cashierNameOrId}
            : <String, dynamic>{};
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(bodyData),
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          debugPrint('✅ Logout kasir berhasil di backend MariaDB ($activeBase)');
          return true;
        }
        debugPrint('⚠️ logoutKasir HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        debugPrint('⚠️ Gagal logout kasir (attempt ${attempt + 1}) via $activeBase: $e');
      }
      _workingBaseUrl = null;
    }
    return false;
  }

  /// Cek apakah kasir tertentu masih berstatus 'Aktif Melayani' di database
  static Future<bool> isKasirActive(String? cashierNameOrId) async {
    if (cashierNameOrId == null || cashierNameOrId.trim().isEmpty) return true;
    try {
      final list = await ambilDaftarKasir();
      if (list.isEmpty) return true; // Fail-safe saat offline/reconnect

      final clean = cashierNameOrId
          .replaceAll(RegExp(r'\s*\(.*?\)'), '')
          .trim()
          .toLowerCase();

      KasirModel? matched;
      for (final c in list) {
        if (c.name.toLowerCase() == clean ||
            c.shortName.toLowerCase() == clean ||
            c.id.toLowerCase() == clean) {
          matched = c;
          break;
        }
      }

      // Jika kasir ini ditemukan di database tapi statusnya sudah Standby / Off
      if (matched != null) {
        return matched.statusLive == 'Aktif Melayani' && matched.isActive;
      }
    } catch (_) {}
    return true;
  }

  /// Cek koneksi ke server backend
  static Future<bool> cekKoneksi() async {
    final activeBase = await getBaseUrl();
    try {
      final url = Uri.parse('$activeBase/transactions');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Model rekapitulasi omset sinkron dengan web / MariaDB
class OmsetSummary {
  final int totalOmset;
  final int totalCount;
  final int tunaiOmset;
  final int tunaiCount;
  final int qrisOmset;
  final int qrisCount;

  const OmsetSummary({
    this.totalOmset = 0,
    this.totalCount = 0,
    this.tunaiOmset = 0,
    this.tunaiCount = 0,
    this.qrisOmset = 0,
    this.qrisCount = 0,
  });

  /// Helper untuk mengecek apakah transaksi terjadi pada hari ini
  static bool isToday(dynamic rawCreated) {
    if (rawCreated == null) return false;
    final dt = DateTime.tryParse(rawCreated.toString())?.toLocal();
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Helper untuk memeriksa apakah nama kasir bersifat generik / tidak spesifik
  static bool _isGenericCashier(String? name) {
    if (name == null) return true;
    final clean = name.toLowerCase().trim();
    return clean.isEmpty ||
        clean == '-' ||
        clean == 'kasir' ||
        clean == 'pilih kasir' ||
        clean == 'kasir prek dua dara' ||
        clean == 'kasir prekduadara';
  }

  /// Helper untuk mencocokkan apakah transaksi dilayani oleh kasir tertentu
  static bool isCashierMatch(String? txCashier, String? targetCashier) {
    if (_isGenericCashier(txCashier) || _isGenericCashier(targetCashier)) {
      return false;
    }
    final tx = txCashier!.toLowerCase().replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    final target = targetCashier!.toLowerCase().replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    if (tx.isEmpty || target.isEmpty) return false;

    if (tx == target) return true;

    // Cek kecocokan nama depan (misal "Rian" dengan "Rian Pratama")
    final txParts = tx.split(RegExp(r'\s+'));
    final targetParts = target.split(RegExp(r'\s+'));
    if (txParts.isNotEmpty && targetParts.isNotEmpty && txParts.first == targetParts.first) {
      if (txParts.length > 1 && targetParts.length > 1) {
        return tx == target;
      }
      return true;
    }

    return false;
  }

  /// Helper untuk mendeteksi apakah transaksi jelas-jelas milik kasir staf lain (dinamis untuk semua kasir)
  static bool isDifferentCashier(String? txCashier, String? currentCashier) {
    if (_isGenericCashier(txCashier) || _isGenericCashier(currentCashier)) {
      return false;
    }
    return !isCashierMatch(txCashier, currentCashier);
  }

  /// Helper untuk mendeteksi nama shift dari kasir atau jam
  static String getShiftName(dynamic rawCreated, {String? timeStr, String? cashier}) {
    // 1. PRIORITAS UTAMA: Nama kasir yang tercatat pada transaksi
    if (cashier != null && cashier.trim().isNotEmpty) {
      final c = cashier.toLowerCase();
      if (c.contains('rian')) return 'Shift Pagi';
      if (c.contains('siti')) return 'Shift Siang';
      if (c.contains('budi')) return 'Shift Malam';
    }

    // 2. FALLBACK: Jam transaksi jika kasir tidak spesifik
    int? hour;
    if (rawCreated != null) {
      final dt = DateTime.tryParse(rawCreated.toString())?.toLocal();
      if (dt != null) hour = dt.hour;
    }
    if (hour == null && timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      hour = int.tryParse(parts[0].trim());
    }

    if (hour != null) {
      if (hour >= 8 && hour < 12) return 'Shift Pagi';
      if (hour >= 12 && hour < 17) return 'Shift Siang';
      return 'Shift Malam';
    }

    return 'Shift Pagi';
  }

  /// Helper untuk mencocokkan shift
  static bool isShiftMatch(String shiftA, String shiftB) {
    final a = shiftA.toLowerCase();
    final b = shiftB.toLowerCase();
    if (a.contains('pagi') && b.contains('pagi')) return true;
    if (a.contains('siang') && b.contains('siang')) return true;
    if (a.contains('malam') && b.contains('malam')) return true;
    return false;
  }

  /// Hitung omset dari list transaksi. Secara default [todayOnly = true] hanya menghitung transaksi hari ini.
  factory OmsetSummary.fromTransactions(
    List<dynamic> list, {
    bool todayOnly = true,
    String? shift,
    String? cashier,
  }) {
    int total = 0;
    int count = 0;
    int tunai = 0;
    int tunaiC = 0;
    int qris = 0;
    int qrisC = 0;

    for (var tx in list) {
      if (tx is Map) {
        // Jika todayOnly aktif, lewati transaksi yang tanggalnya bukan hari ini
        if (todayOnly) {
          final isTxToday = isToday(tx['created_at']);
          if (!isTxToday) continue;
        }

        // Cek kepemilikan kasir / shift
        final txCashier = tx['cashier']?.toString();
        final hasCashier = cashier != null && cashier.isNotEmpty && cashier != 'Pilih Kasir';
        final hasShift = shift != null && shift.isNotEmpty && shift != '-';

        if (hasCashier) {
          if (isCashierMatch(txCashier, cashier)) {
            // Cocok langsung dengan kasir aktif!
          } else if (isDifferentCashier(txCashier, cashier)) {
            // Jelas milik kasir staf lain (misal Rian vs Budi), lewati!
            continue;
          } else if (hasShift) {
            // Kasir generic/tidak dikenal, cocokkan berdasarkan shift
            final txShift = getShiftName(
              tx['created_at'],
              timeStr: tx['time']?.toString(),
              cashier: txCashier,
            );
            if (!isShiftMatch(txShift, shift)) continue;
          }
        } else if (hasShift) {
          final txShift = getShiftName(
            tx['created_at'],
            timeStr: tx['time']?.toString(),
            cashier: txCashier,
          );
          if (!isShiftMatch(txShift, shift)) continue;
        }

        final amount = int.tryParse(tx['total']?.toString() ?? '0') ?? 0;
        final rawMethod = (tx['paymentMethod'] ?? '').toString().toUpperCase();

        total += amount;
        count++;

        if (rawMethod.contains('QRIS')) {
          qris += amount;
          qrisC++;
        } else {
          tunai += amount;
          tunaiC++;
        }
      }
    }

    return OmsetSummary(
      totalOmset: total,
      totalCount: count,
      tunaiOmset: tunai,
      tunaiCount: tunaiC,
      qrisOmset: qris,
      qrisCount: qrisC,
    );
  }
}

/// Model kasir sinkron dengan tabel MariaDB `kasir` & Web Dashboard
class KasirModel {
  final String id; // e.g. '#KSR-001'
  final int? dbId;
  final String name;
  final String roleTitle;
  final String shift;
  final String statusLive;
  final bool isActive;

  KasirModel({
    required this.id,
    this.dbId,
    required this.name,
    this.roleTitle = 'Kasir',
    required this.shift,
    this.statusLive = 'Standby / Rehat',
    this.isActive = true,
  });

  factory KasirModel.fromJson(Map<String, dynamic> json) {
    return KasirModel(
      id: json['id']?.toString() ?? '',
      dbId: json['dbId'] is int
          ? json['dbId']
          : int.tryParse(json['dbId']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Kasir',
      roleTitle: json['roleTitle']?.toString() ?? 'Kasir',
      shift: json['shift']?.toString() ?? 'Shift Pagi (08:00 - 12:00)',
      statusLive: json['statusLive']?.toString() ?? 'Standby / Rehat',
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }

  /// Nama bersih tanpa tanda kurung
  String get shortName => name.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

  /// Nama shift ringkas (Shift Pagi / Shift Siang / Shift Malam / Shift Kustom)
  String get shiftName {
    final s = shift.toLowerCase();
    if (s.contains('siang')) return 'Shift Siang';
    if (s.contains('malam')) return 'Shift Malam';
    if (s.contains('kustom')) return 'Shift Kustom';
    return 'Shift Pagi';
  }

  /// Jam operasional shift
  String get shiftHours {
    final match = RegExp(r'(\d{1,2}[:.]\d{2}\s*[-–]\s*\d{1,2}[:.]\d{2})').firstMatch(shift);
    if (match != null) {
      return '${match.group(1)} WIB';
    }
    final s = shift.toLowerCase();
    if (s.contains('siang')) return '12:00 – 17:00 WIB';
    if (s.contains('malam')) return '17:00 – 22:00 WIB';
    return '08:00 – 12:00 WIB';
  }

  /// Cek apakah jam [now] masuk dalam rentang jam kerja shift kasir ini (termasuk jam kustom & lintas tengah malam)
  bool isWorkingAt(DateTime now) {
    final s = shift.toLowerCase();
    if (s.contains('off') || s.contains('libur')) return false;

    final match = RegExp(
      r'(\d{1,2})[:.](\d{2})\s*[-–]\s*(\d{1,2})[:.](\d{2})',
    ).firstMatch(shift);

    final nowMinutes = now.hour * 60 + now.minute;

    if (match != null) {
      final startH = int.parse(match.group(1)!);
      final startM = int.parse(match.group(2)!);
      final endH = int.parse(match.group(3)!);
      final endM = int.parse(match.group(4)!);

      final startTotal = startH * 60 + startM;
      final endTotal = endH * 60 + endM;

      if (startTotal <= endTotal) {
        return nowMinutes >= startTotal && nowMinutes < endTotal;
      } else {
        // Shift lintas tengah malam (misal 22:00 - 02:00)
        return nowMinutes >= startTotal || nowMinutes < endTotal;
      }
    }

    if (s.contains('pagi')) return now.hour >= 8 && now.hour < 12;
    if (s.contains('siang')) return now.hour >= 12 && now.hour < 17;
    if (s.contains('malam')) return now.hour >= 17 && now.hour < 22;
    return false;
  }
}
