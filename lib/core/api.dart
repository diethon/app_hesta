import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class HestaApi {
  HestaApi({required this.accessToken, required this.onUnauthorized, http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  final String baseUrl;
  final String? Function() accessToken;
  final Future<void> Function() onUnauthorized;
  final http.Client _client;

  Future<Object?> request(String method, String path, {JsonMap? body}) async {
    if (baseUrl.isEmpty) {
      throw const ApiException('Chưa cấu hình API_BASE_URL. Hãy chạy app với --dart-define=API_BASE_URL=...');
    }
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
    final token = accessToken();
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamed).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException('Kết nối quá thời gian. Vui lòng thử lại.');
    } catch (_) {
      throw const ApiException('Không thể kết nối máy chủ. Kiểm tra mạng và địa chỉ API.');
    }

    JsonMap payload;
    try {
      payload = asMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      throw ApiException('Phản hồi từ máy chủ không hợp lệ.', response.statusCode);
    }
    if (response.statusCode == 401 && token != null) await onUnauthorized();
    if (response.statusCode < 200 || response.statusCode >= 300 || payload['code'] != 1000) {
      throw ApiException(
        asText(payload['message']).isNotEmpty ? asText(payload['message']) : 'Yêu cầu không thành công.',
        response.statusCode,
      );
    }
    return payload['result'];
  }

  Future<JsonMap> login(String email, String password) async => asMap(await request('POST', '/auth/login', body: {
    'email': email,
    'password': password,
    'deviceId': 'MOBILE_CLIENT',
    'deviceType': 'MOBILE',
  }));

  Future<void> register(String name, String email, String password, {String? inviteCode}) async {
    await request('POST', '/auth/register', body: {
      'fullName': name,
      'email': email,
      'password': password,
      if (inviteCode != null && inviteCode.isNotEmpty) 'inviteCode': inviteCode,
    });
  }

  Future<void> forgotPassword(String email) async { await request('POST', '/auth/forgot-password', body: {'email': email}); }
  Future<void> verifyOtp(String email, String otp) async { await request('POST', '/auth/verify-otp', body: {'email': email, 'otp': otp}); }
  Future<void> resetPassword(String email, String otp, String password) async { await request('POST', '/auth/reset-password', body: {'email': email, 'otp': otp, 'newPassword': password}); }

  Future<List<HomeSummary>> homes() async => asMapList(await request('GET', '/homes/my-homes')).map(HomeSummary.fromJson).toList(growable: false);
  Future<HomeSummary> createHome(String name) async => HomeSummary.fromJson(asMap(await request('POST', '/homes', body: {'name': name})));
  Future<void> joinHome(String code) async { await request('POST', '/homes/join?codeOrToken=${Uri.encodeQueryComponent(code)}'); }
  Future<List<Room>> rooms(String homeId) async => asMapList(await request('GET', '/homes/$homeId/rooms')).map(Room.fromJson).toList(growable: false);
  Future<List<Device>> devices(String homeId) async => asMapList(await request('GET', '/homes/$homeId/devices')).map(Device.fromJson).toList(growable: false);
  Future<Device> device(String deviceId) async => Device.fromJson(asMap(await request('GET', '/devices/$deviceId')));
  Future<List<JsonMap>> deviceHistory(String deviceId) async => asMapList(await request('GET', '/devices/$deviceId/history'));
  Future<List<HomeScene>> scenes(String homeId) async => asMapList(await request('GET', '/homes/$homeId/scenes')).map(HomeScene.fromJson).toList(growable: false);
  Future<JsonMap> scene(String homeId, String sceneId) async => asMap(await request('GET', '/homes/$homeId/scenes/$sceneId'));
  Future<void> createScene(String homeId, String name, String description) async { await request('POST', '/homes/$homeId/scenes', body: {'name': name, 'description': description, 'enabled': true, 'actions': []}); }
  Future<void> updateScene(String homeId, HomeScene scene, {required bool enabled}) async {
    await request('PUT', '/homes/$homeId/scenes/${scene.id}', body: {'name': scene.name, 'description': scene.description, 'enabled': enabled});
  }
  Future<void> deleteScene(String homeId, String sceneId) async { await request('DELETE', '/homes/$homeId/scenes/$sceneId'); }
  Future<void> addSceneAction(String homeId, String sceneId, String deviceId, String action, int order) async {
    await request('POST', '/homes/$homeId/scenes/$sceneId/actions', body: {'targetDeviceId': deviceId, 'action': action, 'value': null, 'order': order});
  }
  Future<void> removeSceneAction(String homeId, String sceneId, String actionId) async {
    await request('DELETE', '/homes/$homeId/scenes/$sceneId/actions/$actionId');
  }
  Future<List<HomeMember>> members(String homeId) async => asMapList(await request('GET', '/homes/$homeId/members')).map(HomeMember.fromJson).toList(growable: false);
  Future<JsonMap> invite(String homeId, {String? email}) async => asMap(await request('POST', '/homes/$homeId/invitations${email == null ? '' : '?email=${Uri.encodeQueryComponent(email)}'}'));
  Future<void> updateMemberRole(String homeId, String memberId, String role) async {
    await request('PUT', '/homes/$homeId/members/$memberId/role?role=$role');
  }
  Future<void> removeMember(String homeId, String memberId) async {
    await request('DELETE', '/homes/$homeId/members/$memberId');
  }
  Future<HestaUser> updateProfile(String name, String? phone) async => HestaUser.fromJson(asMap(await request('PUT', '/users/me/profile', body: {'fullName': name, 'phoneNumber': phone})));
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await request('PUT', '/users/me/password', body: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }
}
