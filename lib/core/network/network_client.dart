import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/config/providers.dart';
import '../../features/authentication/data/auth_providers.dart';
import '../../features/authentication/domain/auth_repository.dart';
import '../storage/token_storage.dart';
import '../utils/app_logger.dart';
import 'auth_interceptor.dart';

final cloudApiClientProvider = Provider<NetworkClient>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return NetworkClient(
    baseUrl: environment.baseUrl,
    enableLogs: environment.enableVerboseLogs,
    tokenStorage: ref.watch(tokenStorageProvider),
    authRepository: ref.watch(authRepositoryProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final edgeApiClientProvider = Provider<NetworkClient>((ref) {
  return NetworkClient(
    baseUrl: const String.fromEnvironment(
      'EDGE_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    ),
    enableLogs: true,
    tokenStorage: ref.watch(tokenStorageProvider),
    authRepository: ref.watch(authRepositoryProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

class NetworkClient {
  NetworkClient({
    required String baseUrl,
    required bool enableLogs,
    required TokenStore tokenStorage,
    required AuthRepository authRepository,
    required Logger logger,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 20),
           sendTimeout: const Duration(seconds: 20),
           headers: {'Accept': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        authRepository: authRepository,
      ),
    );
    if (enableLogs) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final headers = Map<String, dynamic>.from(options.headers)
              ..remove('Authorization');
            logger.d('${options.method} ${options.uri} $headers');
            handler.next(options);
          },
          onError: (error, handler) {
            logger.w('${error.requestOptions.uri} ${error.message}');
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) {
    return dio.post<T>(path, data: data, cancelToken: cancelToken);
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) {
    return dio.put<T>(path, data: data, cancelToken: cancelToken);
  }

  Future<Response<dynamic>> upload(
    String path, {
    required FormData formData,
    CancelToken? cancelToken,
  }) {
    return dio.post(path, data: formData, cancelToken: cancelToken);
  }

  Future<Response<dynamic>> download(
    String path,
    String savePath, {
    CancelToken? cancelToken,
  }) {
    return dio.download(path, savePath, cancelToken: cancelToken);
  }
}
