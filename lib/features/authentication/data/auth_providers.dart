import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/providers.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import 'api_auth_repository.dart';
import 'mock_auth_repository.dart';

/// Bật lại mock bằng `--dart-define=USE_MOCK=true`.
const bool kUseMockData = bool.fromEnvironment('USE_MOCK');

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  if (kUseMockData) {
    return MockAuthRepository(tokenStorage);
  }

  final environment = ref.watch(appEnvironmentProvider);
  // Dio riêng, KHÔNG qua NetworkClient — AuthInterceptor của NetworkClient
  // phụ thuộc chính AuthRepository này để refresh (tránh vòng lặp provider).
  final dio = Dio(
    BaseOptions(
      baseUrl: environment.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  return ApiAuthRepository(dio: dio, tokenStorage: tokenStorage);
});
