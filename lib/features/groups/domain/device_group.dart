import 'package:flutter/foundation.dart';
import '../../devices/domain/device.dart';

@immutable
class DeviceGroup {
  const DeviceGroup({
    required this.id,
    required this.homeId,
    required this.name,
    this.icon = 'layers',
    this.deviceCount = 0,
    this.deviceIds = const [],
    this.devices = const [],
    this.createdAt,
    this.currentBrightness = 100,
    this.isExecuting = false,
    this.statusMessage,
  });

  final String id;
  final String homeId;
  final String name;
  final String icon;
  final int deviceCount;
  final List<String> deviceIds;
  final List<Device> devices;
  final String? createdAt;
  final int currentBrightness;
  final bool isExecuting;
  final String? statusMessage;

  DeviceGroup copyWith({
    String? name,
    String? icon,
    int? deviceCount,
    List<String>? deviceIds,
    List<Device>? devices,
    String? createdAt,
    int? currentBrightness,
    bool? isExecuting,
    String? statusMessage,
  }) {
    return DeviceGroup(
      id: id,
      homeId: homeId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      deviceCount: deviceCount ?? this.deviceCount,
      deviceIds: deviceIds ?? this.deviceIds,
      devices: devices ?? this.devices,
      createdAt: createdAt ?? this.createdAt,
      currentBrightness: currentBrightness ?? this.currentBrightness,
      isExecuting: isExecuting ?? this.isExecuting,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

@immutable
class GroupCommandResult {
  const GroupCommandResult({
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

  bool get isSuccess => successCount > 0;
}
