import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syna/core/exceptions/app_exception.dart';
import 'package:syna/core/network/auth_interceptor.dart';
import 'package:syna/features/authentication/domain/auth_repository.dart';
import 'package:syna/features/authentication/domain/auth_session.dart';

import '../../support/in_memory_token_storage.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._tokenStorage, {this.refreshShouldFail = false});

  final InMemoryTokenStorage _tokenStorage;
  final bool refreshShouldFail;
  int refreshCalls = 0;

  @override
  Future<AuthSession> refreshToken() async {
    refreshCalls++;
    if (refreshShouldFail) {
      throw const UnauthorizedException();
    }
    await _tokenStorage.saveTokens(
      accessToken: 'new-token',
      refreshToken: 'new-refresh',
    );
    return const AuthSession(
      userId: 'u1',
      email: 'a@b.c',
      name: 'A',
      accessToken: 'new-token',
      refreshToken: 'new-refresh',
    );
  }

  @override
  Future<AuthSession?> restoreSession() => throw UnimplementedError();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}

void main() {
  late HttpServer server;
  late Uri baseUri;

  Future<void> startServer() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUri = Uri.parse('http://${server.address.address}:${server.port}');
    server.listen((request) {
      final auth = request.headers.value(HttpHeaders.authorizationHeader);
      if (auth == 'Bearer new-token') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'success': true, 'data': <Object>[]}));
      } else {
        request.response
          ..statusCode = 401
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'success': false,
              'error': {'code': 'UNAUTHORIZED', 'message': 'Token hết hạn'},
            }),
          );
      }
      request.response.close();
    });
  }

  tearDown(() async {
    await server.close(force: true);
  });

  test('401 → refresh → retry request gốc thành công', () async {
    await startServer();
    final storage = InMemoryTokenStorage();
    await storage.saveTokens(
      accessToken: 'expired-token',
      refreshToken: 'refresh-1',
    );
    final authRepository = _FakeAuthRepository(storage);

    final dio = Dio(BaseOptions(baseUrl: baseUri.toString()))
      ..interceptors.add(
        AuthInterceptor(tokenStorage: storage, authRepository: authRepository),
      );

    final response = await dio.get<Map<String, dynamic>>('/api/v1/devices');

    expect(response.statusCode, 200);
    expect(authRepository.refreshCalls, 1);
    expect(await storage.readAccessToken(), 'new-token');
  });

  test('401 → refresh thất bại → xoá token và ném lỗi', () async {
    await startServer();
    final storage = InMemoryTokenStorage();
    await storage.saveTokens(
      accessToken: 'expired-token',
      refreshToken: 'refresh-1',
    );
    final authRepository = _FakeAuthRepository(
      storage,
      refreshShouldFail: true,
    );

    final dio = Dio(BaseOptions(baseUrl: baseUri.toString()))
      ..interceptors.add(
        AuthInterceptor(tokenStorage: storage, authRepository: authRepository),
      );

    await expectLater(
      dio.get<Map<String, dynamic>>('/api/v1/devices'),
      throwsA(isA<DioException>()),
    );
    expect(authRepository.refreshCalls, 1);
    expect(await storage.readAccessToken(), isNull);
  });
}
