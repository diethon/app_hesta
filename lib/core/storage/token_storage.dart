import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

final tokenStorageProvider = Provider<TokenStore>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

abstract interface class TokenStore {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> saveUserSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String name,
  });

  Future<({String? userId, String? email, String? name})> readUserSession();

  Future<void> clear();
}

class TokenStorage implements TokenStore {
  TokenStorage(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> saveUserSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String name,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userNameKey, value: name);
  }

  @override
  Future<({String? userId, String? email, String? name})> readUserSession() async {
    final userId = await _storage.read(key: _userIdKey);
    final email = await _storage.read(key: _userEmailKey);
    final name = await _storage.read(key: _userNameKey);
    return (userId: userId, email: email, name: name);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userNameKey);
  }
}
