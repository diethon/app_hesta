enum AppEnvironment {
  development,
  staging,
  production;

  String get flavorName => name;

  String get displayName => switch (this) {
    AppEnvironment.development => 'Syna Dev',
    AppEnvironment.staging => 'Syna Staging',
    AppEnvironment.production => 'Syna',
  };

  String get baseUrl => switch (this) {
    AppEnvironment.development => const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    ),
    AppEnvironment.staging => const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://staging-api.example.com',
    ),
    AppEnvironment.production => const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.example.com',
    ),
  };

  /// WebSocket STOMP endpoint kết nối tới backend_hesta (:8080/ws).
  String get wsUrl => switch (this) {
    AppEnvironment.development => const String.fromEnvironment(
      'WS_URL',
      defaultValue: 'ws://10.0.2.2:8080/ws',
    ),
    AppEnvironment.staging => const String.fromEnvironment(
      'WS_URL',
      defaultValue: 'wss://staging-api.example.com/ws',
    ),
    AppEnvironment.production => const String.fromEnvironment(
      'WS_URL',
      defaultValue: 'wss://api.example.com/ws',
    ),
  };

  /// backend_hesta sử dụng chung một WebSocket STOMP endpoint duy nhất (:8080/ws)
  /// cho cả telemetry và notification qua topic /topic/homes/{homeId}/events.
  String get notificationWsUrl => wsUrl;

  bool get isProduction => this == AppEnvironment.production;
  bool get enableVerboseLogs => this == AppEnvironment.development;
}
