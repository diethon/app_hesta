import '../../domain/auth_session.dart';

/// Khớp DTO UserResponse từ backend_hesta (`id`, `fullName`, `email`, `avatarUrl`, `phoneNumber`).
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.phoneNumber,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: (json['id'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    name: (json['fullName'] ?? json['name'] ?? '').toString(),
    avatarUrl: json['avatarUrl']?.toString(),
    phoneNumber: json['phoneNumber']?.toString(),
    createdAt: json['createdAt']?.toString(),
  );

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt,
  };
}

class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    this.refreshToken = '',
    this.expiresIn = 86400,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final UserDto user;
    if (userJson is Map<String, dynamic>) {
      user = UserDto.fromJson(userJson);
    } else if (userJson is Map) {
      user = UserDto.fromJson(Map<String, dynamic>.from(userJson));
    } else {
      user = UserDto(
        id: (json['id'] ?? json['userId'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        name: (json['fullName'] ?? json['name'] ?? '').toString(),
        avatarUrl: json['avatarUrl']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
      );
    }

    return AuthResponseDto(
      accessToken: (json['accessToken'] ?? json['token'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 86400,
      user: user,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserDto user;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'user': user.toJson(),
  };

  AuthSession toSession() {
    return AuthSession(
      userId: user.id,
      email: user.email,
      name: user.name,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
