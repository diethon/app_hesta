import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/camera/data/mock_camera_repository.dart';
import 'package:syna/features/camera/domain/fall_incident.dart';

void main() {
  group('Camera AI & Fall Detection Domain Tests (PHO-040)', () {
    test('FallIncident parses JSON from Spring Boot correctly', () {
      final json = {
        'id': 'inc-999',
        'homeId': 'home-uuid-1',
        'deviceId': 'cam-101',
        'roomName': 'Phòng Khách',
        'incidentType': 'ACCIDENTAL_FALL',
        'state': 'DETECTED',
        'confidenceScore': 0.96,
        'countdownRemainingSec': 30,
        'detectedAt': '2026-03-25T14:30:00Z',
        'metrics': {
          'v_norm': 2.1,
          'accel_g': 3.2,
          'spine_angle': 85.5,
          'motion_energy': 5.4,
        },
        'snapshotUrl': 'http://10.0.2.2:5000/video_feed',
      };

      final incident = FallIncident.fromJson(json);

      expect(incident.id, 'inc-999');
      expect(incident.roomName, 'Phòng Khách');
      expect(incident.incidentType, 'ACCIDENTAL_FALL');
      expect(incident.state, 'DETECTED');
      expect(incident.confidenceScore, 0.96);
      expect(incident.countdownRemainingSec, 30);
      expect(incident.isActive, isTrue);
      expect(incident.isEscalated, isFalse);
      expect(incident.metrics.spineAngle, 85.5);
      expect(incident.metrics.accelG, 3.2);
      expect(incident.localizedType, contains('Té Ngã Vô Ý'));
    });

    test('AiStatus parses JSON correctly', () {
      final json = {
        'fps': 30,
        'alert': true,
        'state': 'FALLEN',
        'incident_type': 'ACCIDENTAL_FALL',
        'metrics': {
          'spine_angle': 88.0,
        },
      };

      final status = AiStatus.fromJson(json);

      expect(status.isOnline, isTrue);
      expect(status.fps, 30);
      expect(status.alert, isTrue);
      expect(status.state, 'FALLEN');
      expect(status.metrics.spineAngle, 88.0);
    });

    test('MockCameraRepository triggers demo fall and handles dismissal', () async {
      final repo = MockCameraRepository();

      // Initial state
      final initial = await repo.getActiveIncidents(null);
      expect(initial.isEmpty, isTrue);

      // Trigger demo
      final triggered = await repo.triggerDemoFall();
      expect(triggered, isTrue);

      final active = await repo.getActiveIncidents(null);
      expect(active.length, 1);
      expect(active.first.isActive, isTrue);
      expect(active.first.metrics.spineAngle, greaterThan(80.0));

      // Dismiss incident
      await repo.dismissIncident(active.first.id);
      final afterDismiss = await repo.getActiveIncidents(null);
      expect(afterDismiss.isEmpty, isTrue);
    });
  });
}
