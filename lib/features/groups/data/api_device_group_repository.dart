import 'package:dio/dio.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/device_group.dart';
import '../domain/device_group_repository.dart';
import 'models/device_group_dto.dart';

class ApiDeviceGroupRepository implements DeviceGroupRepository {
  ApiDeviceGroupRepository(this._client);

  final NetworkClient _client;

  @override
  Future<List<DeviceGroup>> getGroups(String homeId) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/v1/homes/$homeId/device-groups',
      );
      final rawData = response.data;
      final body = rawData is Map
          ? (rawData['result'] ?? rawData['data'] ?? rawData)
          : rawData;

      if (body is List) {
        return body
            .whereType<Map<String, dynamic>>()
            .map((item) => DeviceGroupDto.fromJson(item).toDomain())
            .toList();
      }
      return const <DeviceGroup>[];
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Không thể tải danh sách nhóm: $e');
    }
  }

  @override
  Future<DeviceGroup> createGroup({
    required String homeId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  }) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/homes/$homeId/device-groups',
        data: {'name': name, 'icon': icon ?? 'layers', 'deviceIds': deviceIds},
      );
      final rawData = response.data;
      final body = rawData is Map
          ? (rawData['result'] ?? rawData['data'] ?? rawData)
          : rawData;

      if (body is Map<String, dynamic>) {
        return DeviceGroupDto.fromJson(body).toDomain();
      }
      throw const NetworkException('Phản hồi tạo nhóm không hợp lệ');
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Lỗi khi tạo nhóm thiết bị: $e');
    }
  }

  @override
  Future<DeviceGroup> updateGroup({
    required String groupId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  }) async {
    try {
      final response = await _client.put<dynamic>(
        '/api/v1/device-groups/$groupId',
        data: {'name': name, 'icon': icon ?? 'layers', 'deviceIds': deviceIds},
      );
      final rawData = response.data;
      final body = rawData is Map
          ? (rawData['result'] ?? rawData['data'] ?? rawData)
          : rawData;

      if (body is Map<String, dynamic>) {
        return DeviceGroupDto.fromJson(body).toDomain();
      }
      throw const NetworkException('Phản hồi cập nhật nhóm không hợp lệ');
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Lỗi khi cập nhật nhóm: $e');
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      await _client.dio.delete<dynamic>('/api/v1/device-groups/$groupId');
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Lỗi khi xóa nhóm: $e');
    }
  }

  @override
  Future<GroupCommandResult> sendGroupCommand({
    required String groupId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/device-groups/$groupId/command',
        data: {
          'action': action,
          'parameters': parameters ?? <String, dynamic>{},
        },
      );
      final rawData = response.data;
      final body = rawData is Map
          ? (rawData['result'] ?? rawData['data'] ?? rawData)
          : rawData;

      if (body is Map<String, dynamic>) {
        return GroupCommandResponseDto.fromJson(body).toDomain();
      }
      return GroupCommandResult(
        groupId: groupId,
        action: action,
        totalDevices: 1,
        successCount: 1,
        failureCount: 0,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Lỗi khi gửi lệnh nhóm: $e');
    }
  }
}
