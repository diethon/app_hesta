import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'models/auth_dtos.dart';

/// Repository thật gọi smarthome-gateway (:8080 → auth-service).
///
/// Dùng Dio RIÊNG (không đi qua NetworkClient/AuthInterceptor) để tránh
/// vòng lặp provider: AuthInterceptor của NetworkClient phụ thuộc
/// AuthRepository để refresh token. Bearer được gắn thủ công cho các
/// endpoint cần đăng nhập.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required Dio dio, required TokenStore tokenStorage})
    : _dio = dio,
      _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStore _tokenStorage;

  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (accessToken == null || refreshToken == null) {
        return null;
      }

      final savedUser = await _tokenStorage.readUserSession();
      if (savedUser.userId != null && savedUser.email != null) {
        _session = AuthSession(
          userId: savedUser.userId!,
          email: savedUser.email!,
          name: savedUser.name ?? savedUser.email!.split('@').first,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Xác thực token với backend_hesta qua một request nhẹ
        try {
          await _dio.get<Map<String, dynamic>>(
            '/api/v1/homes/my-homes',
            options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          );
          return _session;
        } on DioException catch (e) {
          // Token không hợp lệ / signature không khớp / hết hạn (401, 403, 500)
          final statusCode = e.response?.statusCode;
          if (statusCode == 401 || statusCode == 403 || statusCode == 500) {
            await _tokenStorage.clear();
            _session = null;
            return null;
          }
          // Lỗi mạng offline: cho phép dùng session đã lưu
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            return _session;
          }
          await _tokenStorage.clear();
          _session = null;
          return null;
        }
      }

      // Có token tồn dư từ backend cũ nhưng chưa có session backend_hesta:
      // Xoá sạch để chuyển về màn hình đăng nhập an toàn.
      await _tokenStorage.clear();
      _session = null;
      return null;
    } catch (_) {
      await _tokenStorage.clear();
      _session = null;
      return null;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    return _saveSession(AuthResponseDto.fromJson(data));
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // backend_hesta AuthController.register yêu cầu { fullName, email, password }
    // và trả về ApiResponse<UserResponse>. Sau khi đăng ký thành công, tự động đăng nhập.
    await _post('/api/v1/auth/register', {
      'fullName': name,
      'email': email,
      'password': password,
    });
    return login(email: email, password: password);
  }

  @override
  Future<AuthSession> refreshToken() async {
    final currentRefreshToken = await _tokenStorage.readRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw const UnauthorizedException('Phiên đăng nhập đã hết hạn.');
    }
    // backend_hesta chưa mở controller endpoint cho refreshToken.
    // Khi token hết hạn, báo UnauthorizedException để chuyển người dùng về login.
    throw const UnauthorizedException('Phiên đăng nhập đã hết hạn.');
  }

  @override
  Future<void> logout() async {
    // backend_hesta chưa có endpoint logout riêng, xóa token cục bộ
    _session = null;
    await _tokenStorage.clear();
  }

  @override
  Future<void> deleteAccount() async {
    _session = null;
    await _tokenStorage.clear();
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      return _unwrap(response);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// Bóc envelope `{ code: 1000, message: "...", result: { ... } }` của backend_hesta.
  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    dynamic raw = response.data;
    if (raw == null) {
      throw const UnknownException('Empty response from server.');
    }

    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        throw const UnknownException('Phản hồi từ máy chủ không hợp lệ.');
      }
    }

    if (raw is! Map) {
      throw const UnknownException('Phản hồi từ máy chủ không hợp lệ.');
    }

    final body = Map<String, dynamic>.from(raw);
    final code = body['code'];
    if (code != null && code != 1000) {
      throw ValidationException(body['message'] as String? ?? 'Yêu cầu thất bại.');
    }

    // backend_hesta đặt dữ liệu ở `result`
    final result = body['result'];
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    // Fallback cho backend cũ nếu có
    final legacyData = body['data'];
    if (legacyData is Map) {
      return Map<String, dynamic>.from(legacyData);
    }

    // Nếu response phẳng chứa token
    if (body.containsKey('accessToken') || body.containsKey('token')) {
      return body;
    }

    // Trường hợp result là null nhưng thành công (ví dụ ApiResponse<Void>)
    return <String, dynamic>{};
  }

  Future<AuthSession> _saveSession(AuthResponseDto dto) async {
    await _tokenStorage.saveUserSession(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      userId: dto.user.id,
      email: dto.user.email,
      name: dto.user.name,
    );
    _session = dto.toSession();
    return _session!;
  }
}
