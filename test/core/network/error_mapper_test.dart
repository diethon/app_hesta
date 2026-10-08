import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syna/core/exceptions/app_exception.dart';
import 'package:syna/core/network/error_mapper.dart';

DioException _httpError(int statusCode, {String? code, String? message}) {
  final requestOptions = RequestOptions(path: '/api/v1/test');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: code == null
          ? null
          : {
              'success': false,
              'error': {'code': code, 'message': message},
            },
    ),
  );
}

void main() {
  test('map theo error.code backend, ưu tiên hơn HTTP status', () {
    expect(
      mapDioException(
        _httpError(401, code: 'INVALID_CREDENTIALS', message: 'Sai mật khẩu'),
      ),
      isA<UnauthorizedException>().having(
        (e) => e.message,
        'message',
        'Sai mật khẩu',
      ),
    );
    expect(
      mapDioException(_httpError(409, code: 'EMAIL_ALREADY_EXISTS')),
      isA<ValidationException>(),
    );
    expect(
      mapDioException(_httpError(404, code: 'DEVICE_NOT_FOUND')),
      isA<NotFoundException>(),
    );
    expect(
      mapDioException(_httpError(422, code: 'VALIDATION_ERROR')),
      isA<ValidationException>(),
    );
    expect(
      mapDioException(_httpError(500, code: 'INTERNAL_ERROR')),
      isA<ServerException>(),
    );
  });

  test('fallback theo HTTP status khi không có error.code', () {
    expect(mapDioException(_httpError(401)), isA<UnauthorizedException>());
    expect(mapDioException(_httpError(403)), isA<ForbiddenException>());
    expect(mapDioException(_httpError(404)), isA<NotFoundException>());
    expect(mapDioException(_httpError(503)), isA<ServerException>());
  });

  test('timeout và lỗi kết nối', () {
    final requestOptions = RequestOptions(path: '/x');
    expect(
      mapDioException(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      ),
      isA<RequestTimeoutException>(),
    );
    expect(
      mapDioException(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        ),
      ),
      isA<NetworkException>(),
    );
  });
}
