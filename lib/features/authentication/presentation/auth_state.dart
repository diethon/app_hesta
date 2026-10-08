import '../domain/auth_session.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.isSubmitting = false,
  });

  const AuthState.checking()
    : status = AuthStatus.checking,
      session = null,
      errorMessage = null,
      isSubmitting = false;

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final bool isSubmitting;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
