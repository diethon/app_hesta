import '../domain/device_group.dart';
import '../domain/device_group_repository.dart';

class MockDeviceGroupRepository implements DeviceGroupRepository {
  final List<DeviceGroup> _groups = [
    const DeviceGroup(
      id: 'grp-living-lights',
      homeId: 'home-mock-1',
      name: 'Đèn Phòng Khách & Ban Công',
      icon: 'lightbulb',
      deviceCount: 3,
      deviceIds: ['dev-light-1', 'dev-light-2', 'dev-light-3'],
      currentBrightness: 85,
      createdAt: '2026-03-15T08:00:00Z',
    ),
    const DeviceGroup(
      id: 'grp-kitchen-appliances',
      homeId: 'home-mock-1',
      name: 'Cụm Thiết Bị Bếp',
      icon: 'kitchen',
      deviceCount: 2,
      deviceIds: ['dev-kitchen-1', 'dev-kitchen-2'],
      currentBrightness: 100,
      createdAt: '2026-03-20T10:30:00Z',
    ),
  ];

  @override
  Future<List<DeviceGroup>> getGroups(String homeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_groups);
  }

  @override
  Future<DeviceGroup> createGroup({
    required String homeId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final newGroup = DeviceGroup(
      id: 'grp-${DateTime.now().millisecondsSinceEpoch}',
      homeId: homeId,
      name: name,
      icon: icon ?? 'layers',
      deviceCount: deviceIds.length,
      deviceIds: deviceIds,
      currentBrightness: 100,
      createdAt: DateTime.now().toIso8601String(),
    );
    _groups.add(newGroup);
    return newGroup;
  }

  @override
  Future<DeviceGroup> updateGroup({
    required String groupId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final updated = _groups[idx].copyWith(
        name: name,
        deviceIds: deviceIds,
        deviceCount: deviceIds.length,
        icon: icon ?? _groups[idx].icon,
      );
      _groups[idx] = updated;
      return updated;
    }
    throw Exception('Nhóm không tồn tại');
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _groups.removeWhere((g) => g.id == groupId);
  }

  @override
  Future<GroupCommandResult> sendGroupCommand({
    required String groupId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final group = _groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => const DeviceGroup(id: '', homeId: '', name: ''),
    );

    int count = group.deviceCount > 0 ? group.deviceCount : 1;
    if (action == 'SET_BRIGHTNESS' &&
        parameters != null &&
        parameters.containsKey('brightness')) {
      final b = (parameters['brightness'] as num).toInt();
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) {
        _groups[idx] = _groups[idx].copyWith(currentBrightness: b);
      }
    }

    return GroupCommandResult(
      groupId: groupId,
      action: action,
      totalDevices: count,
      successCount: count,
      failureCount: 0,
    );
  }
}
