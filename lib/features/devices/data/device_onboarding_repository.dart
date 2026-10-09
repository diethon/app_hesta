import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/device.dart';
import '../domain/device_onboarding_models.dart';
import 'models/device_dto.dart';

abstract interface class DeviceOnboardingRepository {
  Future<DevicePreview> resolveQrToken(String token);

  Future<Device> claimDevice({
    required String deviceId,
    required String token,
    required String homeId,
    required String roomId,
    String? name,
    String? nodeCode,
  });
}

class ApiDeviceOnboardingRepository implements DeviceOnboardingRepository {
  ApiDeviceOnboardingRepository(this._client);

  final NetworkClient _client;

  @override
  Future<DevicePreview> resolveQrToken(String token) async {
    try {
      final response = await _client.get<dynamic>('/api/v1/devices/qr/$token');
      final body = response.data;
      final result = body is Map ? (body['result'] ?? body['data']) : null;
      if (result is! Map<String, dynamic>) {
        throw const UnknownException('Không thể giải mã dữ liệu thiết bị.');
      }
      return DevicePreview.fromJson(result);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Device> claimDevice({
    required String deviceId,
    required String token,
    required String homeId,
    required String roomId,
    String? name,
    String? nodeCode,
  }) async {
    try {
      final payload = {
        'token': token,
        'homeId': homeId,
        'roomId': roomId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (nodeCode != null && nodeCode.trim().isNotEmpty) 'nodeCode': nodeCode.trim(),
      };

      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/devices/$deviceId/claim',
        data: payload,
      );

      final body = response.data;
      final result = body?['result'];
      if (result is! Map<String, dynamic>) {
        throw const UnknownException('Không thể liên kết thiết bị.');
      }
      return DeviceDto.fromJson(result).toDomain();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

final deviceOnboardingRepositoryProvider = Provider<DeviceOnboardingRepository>((ref) {
  final client = ref.watch(cloudApiClientProvider);
  return ApiDeviceOnboardingRepository(client);
});
