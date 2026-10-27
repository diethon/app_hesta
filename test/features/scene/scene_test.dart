import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/scene/domain/scene.dart';
import 'package:syna/features/scene/presentation/scene_icons.dart';

void main() {
  group('Scene Domain Models', () {
    test('Scene parsing from json and copyWith', () {
      final json = {
        'id': 'scene-123',
        'homeId': 'home-456',
        'name': 'Xem phim',
        'icon': 'movie',
        'description': 'Kịch bản xem phim ban đêm',
        'enabled': true,
        'actions': [
          {
            'id': 'act-1',
            'targetDeviceId': 'dev-1',
            'targetDeviceName': 'Đèn phòng khách',
            'action': 'TURN_OFF',
            'order': 0,
          },
          {
            'id': 'act-2',
            'targetDeviceId': 'dev-2',
            'targetDeviceName': 'Điều hòa',
            'action': 'SET_TEMPERATURE',
            'value': 24,
            'order': 1,
          },
        ],
      };

      final scene = Scene.fromJson(json);

      expect(scene.id, 'scene-123');
      expect(scene.homeId, 'home-456');
      expect(scene.name, 'Xem phim');
      expect(scene.icon, 'movie');
      expect(scene.enabled, true);
      expect(scene.actions.length, 2);
      expect(scene.actions[0].targetDeviceName, 'Đèn phòng khách');
      expect(scene.actions[1].value, 24);

      final updated = scene.copyWith(name: 'Xem phim cuối tuần', enabled: false);
      expect(updated.name, 'Xem phim cuối tuần');
      expect(updated.enabled, false);
      expect(updated.id, 'scene-123');
    });

    test('SceneExecution and detail parsing', () {
      final json = {
        'id': 'exec-1',
        'sceneId': 'scene-123',
        'triggerSource': 'MANUAL',
        'status': 'SUCCESS',
        'startedAt': '2026-10-27T10:00:00Z',
        'completedAt': '2026-10-27T10:00:02Z',
        'resultDetail': [
          {
            'deviceId': 'dev-1',
            'action': 'TURN_OFF',
            'success': true,
            'status': 'OK',
          }
        ],
      };

      final execution = SceneExecution.fromJson(json);
      expect(execution.id, 'exec-1');
      expect(execution.triggerSource, 'MANUAL');
      expect(execution.status, 'SUCCESS');
      expect(execution.resultDetail.length, 1);
      expect(execution.resultDetail.first.success, true);
    });

    test('SceneSchedule serialization', () {
      final schedule = SceneSchedule(
        id: 'sched-1',
        sceneId: 'scene-123',
        time: '20:00',
        repeatDays: const [1, 2, 3, 4, 5],
        enabled: true,
      );

      final json = schedule.toJson();
      expect(json['time'], '20:00');
      expect(json['repeatDays'], [1, 2, 3, 4, 5]);
      expect(json['enabled'], true);
    });
  });

  group('SceneIcons helper', () {
    test('getIcon returns appropriate icon or fallback', () {
      expect(SceneIcons.getIcon('home'), isNotNull);
      expect(SceneIcons.getIcon('movie'), isNotNull);
      expect(SceneIcons.getIcon('bed'), isNotNull);
      expect(SceneIcons.getIcon('non_existent_key'), isNotNull);
      expect(SceneIcons.getIcon(null), isNotNull);
    });
  });
}
