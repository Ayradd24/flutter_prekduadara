import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyPrinterConnected = 'printer_connected';
  static const String _keyLastKasir = 'last_kasir_name';

  // Menyimpan pengaturan tema aplikasi
  static Future<void> setDarkMode(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isEnabled);
  }

  // Membaca pengaturan tema aplikasi
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // Menyimpan koneksi status printer kasir PrekDuaDara
  static Future<void> setPrinterStatus(bool isConnected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrinterConnected, isConnected);
  }

  // Membaca status printer kasir
  static Future<bool> getPrinterStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPrinterConnected) ?? false;
  }

  // Menyimpan kasir terakhir yang bertugas
  static Future<void> setLastKasir(String kasirName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastKasir, kasirName);
  }

  // Membaca kasir terakhir
  static Future<String?> getLastKasir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastKasir);
  }
}

