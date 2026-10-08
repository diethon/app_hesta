import 'dart:async';

import '../../../core/exceptions/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._tokenStorage);

  final TokenStore _tokenStorage;
  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    _session = AuthSession(
      userId: 'user-001',
      email: 'test@gmail.com',
      name: 'Nguyen Toan',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    return _session;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!email.contains('@') || password.length < 6) {
      throw const ValidationException('Email hoặc mật khẩu không hợp lệ.');
    }
    return _save(
      AuthSession(
        userId: 'user-001',
        email: email,
        name: 'Alex',
        accessToken: 'mock-access-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock-refresh-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (name.trim().isEmpty || !email.contains('@') || password.length < 6) {
      throw const ValidationException('Thông tin đăng ký chưa hợp lệ.');
    }
    return _save(
      AuthSession(
        userId: 'user-001',
        email: email,
        name: name,
        accessToken: 'mock-access-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock-refresh-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  @override
  Future<AuthSession> refreshToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final currentRefreshToken = await _tokenStorage.readRefreshToken();
    if (currentRefreshToken == null) {
      throw const UnauthorizedException();
    }
    return _save(
      AuthSession(
        userId: _session?.userId ?? 'user-001',
        email: _session?.email ?? 'demo@syna.local',
        name: _session?.name ?? 'Nguyen Toan',
        accessToken: 'mock-access-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: currentRefreshToken,
      ),
    );
  }

  @override
  Future<void> logout() async {
    _session = null;
    await _tokenStorage.clear();
  }

  @override
  Future<void> deleteAccount() async {
    _session = null;
    await _tokenStorage.clear();
  }

  Future<AuthSession> _save(AuthSession session) async {
    _session = session;
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
