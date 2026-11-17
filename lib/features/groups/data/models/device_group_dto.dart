import '../../domain/device_group.dart';
import '../../../devices/data/models/device_dto.dart';

class DeviceGroupDto {
  const DeviceGroupDto({
    required this.id,
    required this.homeId,
    required this.name,
    this.icon,
    this.deviceCount = 0,
    this.deviceIds = const [],
    this.devices = const [],
    this.createdAt,
  });

  final String id;
  final String homeId;
  final String name;
  final String? icon;
  final int deviceCount;
  final List<String> deviceIds;
  final List<DeviceDto> devices;
  final String? createdAt;

  factory DeviceGroupDto.fromJson(Map<String, dynamic> json) {
    final rawDeviceIds = json['deviceIds'];
    List<String> ids = [];
    if (rawDeviceIds is List) {
      ids = rawDeviceIds.map((e) => e.toString()).toList();
    }

    final rawDevices = json['devices'];
    List<DeviceDto> devList = [];
    if (rawDevices is List) {
      devList = rawDevices
          .whereType<Map<String, dynamic>>()
          .map((m) => DeviceDto.fromJson(m))
          .toList();
    }

    return DeviceGroupDto(
      id: (json['id'] ?? '').toString(),
      homeId: (json['homeId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: json['icon'] as String?,
      deviceCount: json['deviceCount'] is num
          ? (json['deviceCount'] as num).toInt()
          : (ids.isNotEmpty ? ids.length : devList.length),
      deviceIds: ids,
      devices: devList,
      createdAt: json['createdAt'] as String?,
    );
  }

  DeviceGroup toDomain() {
    final domainDevices = devices.map((d) => d.toDomain()).toList();
    return DeviceGroup(
      id: id,
      homeId: homeId,
      name: name,
      icon: icon ?? 'layers',
      deviceCount: deviceCount,
      deviceIds: deviceIds.isNotEmpty ? deviceIds : domainDevices.map((d) => d.id).toList(),
      devices: domainDevices,
      createdAt: createdAt,
    );
  }
}

class GroupCommandResponseDto {
  const GroupCommandResponseDto({
    required this.groupId,
    required this.action,
    required this.totalDevices,
    required this.successCount,
    required this.failureCount,
  });

  final String groupId;
  final String action;
  final int totalDevices;
  final int successCount;
  final int failureCount;

  factory GroupCommandResponseDto.fromJson(Map<String, dynamic> json) {
    return GroupCommandResponseDto(
      groupId: (json['groupId'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      totalDevices: json['totalDevices'] is num ? (json['totalDevices'] as num).toInt() : 0,
      successCount: json['successCount'] is num ? (json['successCount'] as num).toInt() : 0,
      failureCount: json['failureCount'] is num ? (json['failureCount'] as num).toInt() : 0,
    );
  }

  GroupCommandResult toDomain() {
    return GroupCommandResult(
      groupId: groupId,
      action: action,
      totalDevices: totalDevices,
      successCount: successCount,
      failureCount: failureCount,
    );
  }
}
