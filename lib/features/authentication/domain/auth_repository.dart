import 'auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({required String email, required String password});

  /// Đổi Google ID token lấy phiên HESTA (backend verify token).
  Future<AuthSession> loginWithGoogle({required String idToken});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSession> refreshToken();

  Future<void> logout();

  Future<void> deleteAccount();
}
