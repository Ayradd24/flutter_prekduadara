import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'prekduadara_payment_channel';
  static const String _channelName = 'Notifikasi Pembayaran';
  static const String _channelDescription =
      'Notifikasi sistem saat transaksi pembayaran PrekDuaDara berhasil';

  static bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi lokal, izin Android 13+, dan channel heads-up.
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _plugin.initialize(settings: initSettings);

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidImplementation.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Gagal inisialisasi NotificationService: $e');
    }
  }

  static String _formatRupiahNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Tampilkan notifikasi sistem Android (heads-up banner + notification bar)
  /// setiap kali transaksi pembayaran berhasil diproses.
  static Future<void> showPaymentSuccessNotification({
    required String receiptNumber,
    required String paymentMethod,
    required int totalAmount,
    required int cashReceived,
    required int changeAmount,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      final bool isQris = paymentMethod.toUpperCase().contains('QRIS');
      final String title = 'Pembayaran Berhasil • $receiptNumber';
      final String body = isQris
          ? 'Total Rp ${_formatRupiahNumber(totalAmount)} • Pembayaran QRIS Lunas'
          : 'Total Rp ${_formatRupiahNumber(totalAmount)} • Tunai Rp ${_formatRupiahNumber(cashReceived)} (Kembalian Rp ${_formatRupiahNumber(changeAmount)})';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        ticker: 'Pembayaran Berhasil',
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      // ID unik 32-bit berbasis timestamp agar riwayat notifikasi tidak saling menimpa
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: receiptNumber,
      );
    } catch (e) {
      debugPrint('Gagal menampilkan notifikasi pembayaran: $e');
    }
  }
}
