import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/groups/data/mock_device_group_repository.dart';
import 'package:syna/features/groups/data/models/device_group_dto.dart';

void main() {
  group('Device Groups Domain & DTO Tests (PHO-041)', () {
    test('DeviceGroupDto parses backend response correctly', () {
      final json = {
        'id': 'grp-101',
        'homeId': 'home-uuid-1',
        'name': 'Đèn Phòng Ngủ Master',
        'icon': 'lightbulb',
        'deviceCount': 2,
        'deviceIds': ['dev-1', 'dev-2'],
        'createdAt': '2026-03-22T10:00:00Z',
      };

      final dto = DeviceGroupDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.id, 'grp-101');
      expect(domain.name, 'Đèn Phòng Ngủ Master');
      expect(domain.deviceCount, 2);
      expect(domain.deviceIds, contains('dev-1'));
      expect(domain.deviceIds, contains('dev-2'));
      expect(domain.currentBrightness, 100);
    });

    test('GroupCommandResponseDto parses command execution result', () {
      final json = {
        'groupId': 'grp-101',
        'action': 'SET_BRIGHTNESS',
        'totalDevices': 3,
        'successCount': 3,
        'failureCount': 0,
      };

      final dto = GroupCommandResponseDto.fromJson(json);
      final result = dto.toDomain();

      expect(result.groupId, 'grp-101');
      expect(result.action, 'SET_BRIGHTNESS');
      expect(result.totalDevices, 3);
      expect(result.successCount, 3);
      expect(result.isSuccess, isTrue);
    });

    test(
      'MockDeviceGroupRepository performs CRUD and SET_BRIGHTNESS Master Dimmer',
      () async {
        final repo = MockDeviceGroupRepository();

        // 1. Get initial groups
        final initialGroups = await repo.getGroups('home-mock-1');
        expect(initialGroups.length, 2);
        expect(initialGroups.first.name, 'Đèn Phòng Khách & Ban Công');

        // 2. Create new group
        final created = await repo.createGroup(
          homeId: 'home-mock-1',
          name: 'Nhóm Sân Vườn',
          deviceIds: ['dev-garden-1', 'dev-garden-2'],
        );
        expect(created.name, 'Nhóm Sân Vườn');
        expect(created.deviceCount, 2);

        // Verify list increased
        final afterCreate = await repo.getGroups('home-mock-1');
        expect(afterCreate.length, 3);

        // 3. Test Master Dimmer command
        final cmdRes = await repo.sendGroupCommand(
          groupId: initialGroups.first.id,
          action: 'SET_BRIGHTNESS',
          parameters: {'brightness': 45},
        );
        expect(cmdRes.isSuccess, isTrue);

        final updatedGroups = await repo.getGroups('home-mock-1');
        expect(updatedGroups.first.currentBrightness, 45);

        // 4. Update group (UC-GRP-03)
        final updated = await repo.updateGroup(
          groupId: created.id,
          name: 'Nhóm Sân Vườn Mới',
          deviceIds: ['dev-garden-1'],
        );
        expect(updated.name, 'Nhóm Sân Vườn Mới');
        expect(updated.deviceCount, 1);

        // 5. Delete group
        await repo.deleteGroup(created.id);
        final afterDelete = await repo.getGroups('home-mock-1');
        expect(afterDelete.length, 2);
      },
    );
  });
}
