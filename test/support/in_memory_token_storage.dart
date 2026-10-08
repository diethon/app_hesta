import 'package:syna/core/storage/token_storage.dart';

class InMemoryTokenStorage implements TokenStore {
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _email;
  String? _name;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _name = null;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> saveUserSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String name,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _email = email;
    _name = name;
  }

  @override
  Future<({String? userId, String? email, String? name})> readUserSession() async {
    return (userId: _userId, email: _email, name: _name);
  }
}
