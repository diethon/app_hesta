import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/recommendation/domain/recommendation_models.dart';

void main() {
  group('Recommendation Domain Models', () {
    test('Recommendation fromJson and status properties', () {
      final json = {
        'id': 'rec-1',
        'homeId': 'home-1',
        'deviceId': 'light-1',
        'deviceName': 'Đèn trần',
        'triggerCondition': {
          'type': 'SCHEDULE',
          'time': '19:00',
          'repeatDays': [1, 2, 3, 4, 5],
          'patternType': 'DAILY_EVENING',
        },
        'proposedAction': {
          'deviceId': 'light-1',
          'action': 'TURN_ON',
          'parameters': {},
        },
        'explanation': 'Phát hiện thói quen bật đèn lúc 19:00',
        'confidence': 0.92,
        'status': 'PENDING',
        'engineType': 'ML',
        'modelVersion': 'v2.4.0',
        'createdAt': '2026-10-27T08:00:00Z',
      };

      final rec = Recommendation.fromJson(json);

      expect(rec.id, 'rec-1');
      expect(rec.deviceName, 'Đèn trần');
      expect(rec.confidence, 0.92);
      expect(rec.confidencePercent, 92);
      expect(rec.isPending, true);
      expect(rec.triggerCondition.time, '19:00');
      expect(rec.triggerCondition.repeatDays, [1, 2, 3, 4, 5]);
      expect(rec.proposedAction.action, 'TURN_ON');

      final approved = rec.copyWith(status: 'APPROVED');
      expect(approved.status, 'APPROVED');
      expect(approved.isPending, false);
    });

    test('MlModelStatus calculation and getters', () {
      final json = {
        'status': 'READY',
        'version': 'v2.4.1',
        'modelType': 'BehaviorML',
        'accuracy': 0.935,
        'trainSamples': 250,
        'confidenceThreshold': 0.8,
      };

      final status = MlModelStatus.fromJson(json);
      expect(status.status, 'READY');
      expect(status.isReady, true);
      expect(status.isColdStart, false);
      expect(status.isTraining, false);
      expect(status.accuracyPercent, 94);
      expect(status.trainSamples, 250);
    });
  });
}
