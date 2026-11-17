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

  /// Ambil ringkasan omset shift dari database MariaDB
  static Future<OmsetSummary> ambilOmsetSummary() async {
    final list = await ambilRiwayatTransaksi();
    return OmsetSummary.fromTransactions(list);
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

  factory OmsetSummary.fromTransactions(List<dynamic> list) {
    int total = 0;
    int count = 0;
    int tunai = 0;
    int tunaiC = 0;
    int qris = 0;
    int qrisC = 0;

    for (var tx in list) {
      if (tx is Map) {
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
