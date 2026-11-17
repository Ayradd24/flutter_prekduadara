import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL backend PrekDuaDara
  // Karena menggunakan kabel USB dengan 'adb reverse tcp:5000 tcp:5000',
  // baik di Windows Desktop, Chrome, maupun HP Android (USB), 'http://localhost:5000/api' langsung terhubung ke laptop!
  static String get baseUrl {
    return 'http://localhost:5000/api';
  }

  /// Kirim transaksi pemesanan baru ke database MariaDB
  static Future<Map<String, dynamic>> kirimPesanan({
    required int total,
    required String paymentMethod,
    String? cashier,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Transaksi berhasil disimpan ke MariaDB',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menyimpan transaksi: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error ApiService.kirimPesanan: $e');
      return {
        'success': false,
        'message': 'Koneksi ke backend gagal: $e',
      };
    }
  }

  /// Ambil seluruh riwayat transaksi dari backend MariaDB
  static Future<List<dynamic>> ambilRiwayatTransaksi() async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return json['data'];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error ApiService.ambilRiwayatTransaksi: $e');
      return [];
    }
  }

  /// Ambil ringkasan omset shift dari database MariaDB
  static Future<OmsetSummary> ambilOmsetSummary() async {
    final list = await ambilRiwayatTransaksi();
    return OmsetSummary.fromTransactions(list);
  }

  /// Cek koneksi ke server backend
  static Future<bool> cekKoneksi() async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
