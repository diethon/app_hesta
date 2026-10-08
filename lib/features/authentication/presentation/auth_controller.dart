import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/app_exception.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider))..restore();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.checking());

  final AuthRepository _repository;

  Future<void> restore() async {
    final session = await _repository.restoreSession();
    state = AuthState(
      status: session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      session: session,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final session = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } on AppException catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
        isSubmitting: false,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Đăng nhập không thành công: ${error.toString()}',
        isSubmitting: false,
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final session = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } on AppException catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
        isSubmitting: false,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Đăng ký không thành công: ${error.toString()}',
        isSubmitting: false,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
