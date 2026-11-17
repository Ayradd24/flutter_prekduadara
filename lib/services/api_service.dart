import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Daftar kandidat endpoint backend:
  // 1. localhost:5000 (Untuk USB adb reverse, Windows Desktop, dan Chrome)
  // 2. 192.168.10.120:5000 (IP Wi-Fi laptop, berfungsi bila HP di jaringan Wi-Fi sama)
  // 3. 10.0.2.2:5000 (Untuk Android Emulator)
  static final List<String> candidateUrls = [
    'http://localhost:5000/api',
    'http://192.168.10.120:5000/api',
    'http://10.0.2.2:5000/api',
  ];

  static String? _workingBaseUrl;

  /// Dapatkan base URL yang aktif
  static Future<String> getBaseUrl() async {
    if (_workingBaseUrl != null) {
      return _workingBaseUrl!;
    }

    for (final candidate in candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$candidate/transactions'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _workingBaseUrl = candidate;
          debugPrint('✅ ApiService terhubung ke: $candidate');
          return candidate;
        }
      } catch (_) {
        // Coba kandidat berikutnya
      }
    }

    return candidateUrls.first;
  }

  static String get baseUrl => _workingBaseUrl ?? candidateUrls.first;

  /// Kirim transaksi pemesanan baru ke database MariaDB
  static Future<Map<String, dynamic>> kirimPesanan({
    required int total,
    required String paymentMethod,
    String? cashier,
    required List<Map<String, dynamic>> items,
  }) async {
    final activeBase = await getBaseUrl();
    final orderedCandidates = [
      activeBase,
      ...candidateUrls.where((u) => u != activeBase),
    ];

    String lastError = 'Koneksi ke backend gagal';

    for (final base in orderedCandidates) {
      try {
        final url = Uri.parse('$base/transactions');
        final payload = jsonEncode({
          'total': total,
          'paymentMethod': paymentMethod, // 'Tunai' atau 'QRIS'
          'cashier': cashier ?? 'Kasir Prek Dua Dara',
          'items': items,
        });

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = base;
          final data = jsonDecode(response.body);
          debugPrint('✅ Berhasil kirim pesanan via $base');
          return {
            'success': true,
            'message': data['message'] ?? 'Transaksi berhasil disimpan ke MariaDB',
            'data': data['data'],
            'activeUrl': base,
          };
        } else {
          lastError = 'HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = '$e';
        debugPrint('Gagal kirim pesanan via $base: $e');
      }
    }

    return {
      'success': false,
      'message': 'Gagal menyimpan transaksi: $lastError',
    };
  }

  /// Ambil seluruh riwayat transaksi dari backend MariaDB
  static Future<List<dynamic>> ambilRiwayatTransaksi() async {
    final activeBase = await getBaseUrl();
    final orderedCandidates = [
      activeBase,
      ...candidateUrls.where((u) => u != activeBase),
    ];

    for (final base in orderedCandidates) {
      try {
        final url = Uri.parse('$base/transactions');
        final response = await http.get(url).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['success'] == true && json['data'] is List) {
            _workingBaseUrl = base;
            debugPrint('✅ Ambil transaksi sukses dari $base: ${(json['data'] as List).length} item');
            return json['data'];
          }
        }
      } catch (e) {
        debugPrint('Gagal ambil riwayat dari $base: $e');
      }
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
    final orderedCandidates = [
      activeBase,
      ...candidateUrls.where((u) => u != activeBase),
    ];

    for (final base in orderedCandidates) {
      try {
        final url = Uri.parse('$base/cashiers');
        final response = await http.get(url).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['success'] == true && json['data'] is List) {
            _workingBaseUrl = base;
            final list = (json['data'] as List)
                .map((item) => KasirModel.fromJson(item as Map<String, dynamic>))
                .toList();
            return list;
          }
        }
      } catch (e) {
        debugPrint('Gagal ambil daftar kasir dari $base: $e');
      }
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
    final orderedCandidates = [
      activeBase,
      ...candidateUrls.where((u) => u != activeBase),
    ];

    String lastError = 'Koneksi ke backend gagal';

    for (final base in orderedCandidates) {
      try {
        final encodedId = Uri.encodeComponent(idOrCode);
        final url = Uri.parse('$base/cashiers/$encodedId');
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
          _workingBaseUrl = base;
          final json = jsonDecode(response.body);
          return {
            'success': true,
            'message': json['message'] ?? 'Nama kasir berhasil diperbarui',
            'data': json['data'],
          };
        } else {
          lastError = 'HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = '$e';
        debugPrint('Gagal update nama kasir via $base: $e');
      }
    }

    return {
      'success': false,
      'message': 'Gagal memperbarui nama kasir: $lastError',
    };
  }

  /// Tambah staf kasir baru ke database MariaDB
  static Future<Map<String, dynamic>> tambahKasir({
    required String name,
    required String shift,
  }) async {
    final activeBase = await getBaseUrl();
    final orderedCandidates = [
      activeBase,
      ...candidateUrls.where((u) => u != activeBase),
    ];

    String lastError = 'Koneksi ke backend gagal';

    for (final base in orderedCandidates) {
      try {
        final url = Uri.parse('$base/cashiers');
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
          _workingBaseUrl = base;
          final json = jsonDecode(response.body);
          return {
            'success': true,
            'message': json['message'] ?? 'Kasir baru berhasil didaftarkan',
            'data': json['data'],
          };
        } else {
          lastError = 'HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = '$e';
        debugPrint('Gagal tambah kasir via $base: $e');
      }
    }

    return {
      'success': false,
      'message': 'Gagal menambahkan kasir: $lastError',
    };
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

  /// Helper untuk mencocokkan apakah transaksi dilayani oleh kasir tertentu
  static bool isCashierMatch(String? txCashier, String? targetCashier) {
    if (txCashier == null || targetCashier == null) return false;
    final tx = txCashier.toLowerCase().replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    final target = targetCashier.toLowerCase().replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    if (tx.isEmpty || target.isEmpty) return false;

    if (tx == target) return true;

    // Cek kecocokan nama depan (misal "Rian" dengan "Rian Pratama")
    final txFirst = tx.split(RegExp(r'\s+')).first;
    final targetFirst = target.split(RegExp(r'\s+')).first;
    if (txFirst.isNotEmpty && targetFirst.isNotEmpty && txFirst == targetFirst) {
      return true;
    }

    return tx.contains(target) || target.contains(tx);
  }

  /// Helper untuk mendeteksi apakah transaksi jelas-jelas milik kasir staf lain
  static bool isDifferentCashier(String? txCashier, String? currentCashier) {
    if (txCashier == null || currentCashier == null) return false;
    final tx = txCashier.toLowerCase();
    final cur = currentCashier.toLowerCase();

    const knownCashiers = ['rian', 'siti', 'budi'];
    String? txKnown;
    for (var k in knownCashiers) {
      if (tx.contains(k)) {
        txKnown = k;
        break;
      }
    }

    String? curKnown;
    for (var k in knownCashiers) {
      if (cur.contains(k)) {
        curKnown = k;
        break;
      }
    }

    if (txKnown != null && curKnown != null) {
      return txKnown != curKnown;
    }

    return false;
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

  /// Nama shift ringkas (Shift Pagi / Shift Siang / Shift Malam)
  String get shiftName {
    final s = shift.toLowerCase();
    if (s.contains('siang')) return 'Shift Siang';
    if (s.contains('malam')) return 'Shift Malam';
    return 'Shift Pagi';
  }

  /// Jam operasional shift
  String get shiftHours {
    final match = RegExp(r'(\d{1,2}[:.]\d{2}\s*-\s*\d{1,2}[:.]\d{2})').firstMatch(shift);
    if (match != null) {
      return '${match.group(1)} WIB';
    }
    final s = shift.toLowerCase();
    if (s.contains('siang')) return '12:00 – 17:00 WIB';
    if (s.contains('malam')) return '17:00 – 22:00 WIB';
    return '08:00 – 12:00 WIB';
  }
}
