import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/authentication/domain/auth_repository.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStorage,
    required AuthRepository authRepository,
  }) : _tokenStorage = tokenStorage,
       _authRepository = authRepository;

  final TokenStore _tokenStorage;
  final AuthRepository _authRepository;
  Completer<void>? _refreshCompleter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['tokenRetried'] == true;
    if (statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      await _refreshTokenOnce();
      final request = err.requestOptions..extra['tokenRetried'] = true;
      final dio = Dio(BaseOptions(baseUrl: request.baseUrl));
      final accessToken = await _tokenStorage.readAccessToken();
      request.headers['Authorization'] = 'Bearer $accessToken';
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      await _tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<void> _refreshTokenOnce() async {
    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<void>();
    // Không có request nào khác chờ refresh thì lỗi của completer
    // không được ai lắng nghe → tránh unhandled async error.
    completer.future.ignore();
    _refreshCompleter = completer;
    try {
      await _authRepository.refreshToken();
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
