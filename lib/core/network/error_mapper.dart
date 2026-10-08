import 'package:dio/dio.dart';

import '../exceptions/app_exception.dart';

/// Đọc body lỗi chuẩn của backend_hesta:
/// `{ code: 1006, message: "...", result: null }`
/// và fallback cho format cũ `{ success: false, error: { code, message } }`.
({String? code, String? message}) readBackendError(Object? data) {
  if (data is Map<String, dynamic>) {
    if (data.containsKey('code')) {
      return (
        code: data['code']?.toString(),
        message: data['message'] as String?,
      );
    }
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      return (
        code: error['code']?.toString(),
        message: error['message'] as String?,
      );
    }
  }
  return (code: null, message: null);
}

AppException mapDioException(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return const RequestTimeoutException();
  }
  if (error.type == DioExceptionType.connectionError) {
    return const NetworkException();
  }

  final backendError = readBackendError(error.response?.data);
  final message = backendError.message;

  // Ưu tiên error.code từ backend_hesta (chuỗi hoặc mã số 1001-9999).
  switch (backendError.code) {
    // backend_hesta ErrorCodes
    case '1004':
    case 'UNAUTHENTICATED':
    case 'UNAUTHORIZED':
      return UnauthorizedException(message ?? 'Session expired.');
    case '1005':
    case 'FORBIDDEN':
      return ForbiddenException(message ?? 'Access denied.');
    case '1006':
    case 'INVALID_CREDENTIALS':
      return UnauthorizedException(message ?? 'Email hoặc mật khẩu không chính xác.');
    case '1002':
    case 'USER_EXISTED':
    case 'EMAIL_ALREADY_EXISTS':
    case '1017':
    case '1018':
    case '1019':
    case '1020':
    case '1021':
    case '1022':
    case '1031': // INVALID_DEVICE_ACTION
    case '1032': // INVALID_RGB_VALUE
    case '1033': // INVALID_BRIGHTNESS_VALUE
    case '1036': // AC_TEMPERATURE_INVALID
    case '1037': // AC_MODE_INVALID
    case '1038': // AC_FAN_INVALID
    case '1039': // AC_TIMER_INVALID
    case '1040': // GATE_ACTION_INVALID
    case 'VALIDATION_ERROR':
    case 'MALFORMED_REQUEST':
    case 'INVALID_ACTION':
    case 'INVALID_PAYLOAD':
    case 'INVALID_DEVICE_TYPE':
      return ValidationException(message ?? 'Dữ liệu không hợp lệ.');
    case '1003': // USER_NOT_FOUND
    case '1100': // HOME_NOT_FOUND
    case '1101': // SCENE_NOT_FOUND
    case '1102': // DEVICE_NOT_FOUND
    case '1103': // NODE_NOT_FOUND
    case '1200': // AUTOMATION_RULE_NOT_FOUND
    case '1400': // NOTIFICATION_NOT_FOUND
    case 'NOT_FOUND':
    case 'DEVICE_NOT_FOUND':
    case 'USER_NOT_FOUND':
    case 'ROOM_NOT_FOUND':
    case 'HOME_NOT_FOUND':
    case 'SCENE_NOT_FOUND':
    case 'RULE_NOT_FOUND':
    case 'NOTIFICATION_NOT_FOUND':
      return NotFoundException(message ?? 'Không tìm thấy tài nguyên.');
    case '9999':
    case '1035': // MQTT_PUBLISH_FAILED
    case 'INTERNAL_ERROR':
      return ServerException(message ?? 'Lỗi máy chủ.');
  }

  final statusCode = error.response?.statusCode;
  return switch (statusCode) {
    400 || 409 || 422 => ValidationException(message ?? 'Invalid request.'),
    401 => UnauthorizedException(message ?? 'Session expired.'),
    403 => ForbiddenException(message ?? 'Access denied.'),
    404 => NotFoundException(message ?? 'Resource not found.'),
    != null && >= 500 => ServerException(message ?? 'Server error.'),
    _ => UnknownException(message ?? 'Unexpected error.'),
  };
}
