import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Inisialisasi secure storage
  final _storage = const FlutterSecureStorage();

  static const _keyAuthToken = 'user_auth_token';
  static const _keySecretKey = 'api_secret_key';

  // Menyimpan Token Login dengan aman dan terenkripsi
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  // Membaca Token Login yang tersimpan
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  // Menghapus Token saat pengguna (kasir) melakukan Logout
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _keyAuthToken);
  }
}
