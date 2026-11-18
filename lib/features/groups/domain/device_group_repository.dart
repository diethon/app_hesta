import 'device_group.dart';

abstract class DeviceGroupRepository {
  Future<List<DeviceGroup>> getGroups(String homeId);

  Future<DeviceGroup> createGroup({
    required String homeId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  });

  Future<DeviceGroup> updateGroup({
    required String groupId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  });

  Future<void> deleteGroup(String groupId);

  Future<GroupCommandResult> sendGroupCommand({
    required String groupId,
    required String action,
    Map<String, dynamic>? parameters,
  });
}
