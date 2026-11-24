import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/exceptions/app_exception.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

/// Web OAuth client id — backend verify ID token với audience này
/// (`app.google.client-id`), nên Android/iOS phải xin token cho server này.
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '962352236636-panbra9em73iofocv7r96hj200i40igl.apps.googleusercontent.com',
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider))..restore();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.checking());

  final AuthRepository _repository;
  static bool _googleInitialized = false;

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

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await google.initialize(serverClientId: _googleServerClientId);
        _googleInitialized = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'Không nhận được ID token từ Google.',
        );
      }
      final session = await _repository.loginWithGoogle(idToken: idToken);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } on GoogleSignInException catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        // Người dùng tự đóng hộp chọn tài khoản → không coi là lỗi.
        errorMessage: error.code == GoogleSignInExceptionCode.canceled
            ? null
            : 'Đăng nhập Google thất bại: ${error.description ?? error.code.name}',
        clearError: error.code == GoogleSignInExceptionCode.canceled,
        isSubmitting: false,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
        isSubmitting: false,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Đăng nhập Google thất bại: ${error.toString()}',
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
    if (_googleInitialized) await GoogleSignIn.instance.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
