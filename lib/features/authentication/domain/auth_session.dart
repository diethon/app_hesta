class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String email;
  final String name;
  final String accessToken;
  final String refreshToken;
}
