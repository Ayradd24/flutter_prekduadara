import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Inisialisasi secure storage
  final _storage = const FlutterSecureStorage();

  static const _keyAuthToken = 'user_auth_token';
  static const _keyCurrentKasir = 'current_kasir';
  static const _keyCurrentShift = 'current_shift';

  // Menyimpan Token Login dengan aman dan terenkripsi
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  // Membaca Token Login yang tersimpan
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  // Menyimpan info sesi kasir aktif
  Future<void> saveSession({required String kasir, required String shift}) async {
    await _storage.write(key: _keyCurrentKasir, value: kasir);
    await _storage.write(key: _keyCurrentShift, value: shift);
    await _storage.write(
      key: _keyAuthToken,
      value: 'token_${kasir.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Membaca kasir aktif
  Future<String?> getCurrentKasir() async {
    return await _storage.read(key: _keyCurrentKasir);
  }

  // Membaca shift aktif
  Future<String?> getCurrentShift() async {
    return await _storage.read(key: _keyCurrentShift);
  }

  // Menghapus Sesi/Token saat kasir menutup shift / logout
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyCurrentKasir);
    await _storage.delete(key: _keyCurrentShift);
  }
}

