sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed.']);
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'Request timed out.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired.']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Access denied.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Invalid request.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error.']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Unexpected error.']);
}
