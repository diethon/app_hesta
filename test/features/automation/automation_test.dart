import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/automation/domain/automation_models.dart';

void main() {
  group('Automation Rule Domain Models', () {
    test('AutomationRule fromJson and operator symbols', () {
      final json = {
        'id': 'rule-1',
        'homeId': 'home-1',
        'name': 'Bảo vệ nhiệt độ',
        'description': 'Bật điều hòa khi quá nóng',
        'triggerType': 'SENSOR',
        'enabled': true,
        'conditions': [
          {
            'id': 'cond-1',
            'deviceId': 'temp-sensor-1',
            'deviceName': 'Cảm biến nhiệt độ',
            'attribute': 'temperature',
            'operator': 'GT',
            'expectedValue': 30,
            'logicalOperator': 'AND',
            'order': 0,
          },
        ],
        'actions': [
          {
            'id': 'act-1',
            'deviceId': 'ac-1',
            'deviceName': 'Điều hòa',
            'action': 'SET_TEMPERATURE',
            'parameters': {'temperature': 24},
            'order': 0,
          },
        ],
      };

      final rule = AutomationRule.fromJson(json);

      expect(rule.id, 'rule-1');
      expect(rule.name, 'Bảo vệ nhiệt độ');
      expect(rule.triggerType, 'SENSOR');
      expect(rule.enabled, true);
      expect(rule.conditions.length, 1);
      expect(rule.conditions[0].operatorSymbol, '>');
      expect(rule.conditions[0].expectedValue, 30);
      expect(rule.actions.length, 1);
      expect(rule.actions[0].action, 'SET_TEMPERATURE');
      expect(rule.actions[0].parameters['temperature'], 24);

      final toggled = rule.copyWith(enabled: false);
      expect(toggled.enabled, false);
      expect(toggled.name, 'Bảo vệ nhiệt độ');
    });

    test('Operator symbols for all operators', () {
      const ops = [
        ('EQ', '='),
        ('NE', '!='),
        ('GT', '>'),
        ('GTE', '>='),
        ('LT', '<'),
        ('LTE', '<='),
      ];

      for (final (op, sym) in ops) {
        final cond = RuleCondition(
          attribute: 'attr',
          operator: op,
          expectedValue: 1,
        );
        expect(cond.operatorSymbol, sym);
      }
    });

    test('AutomationExecution parsing', () {
      // Backend AutomationExecutionResponse shape.
      final json = {
        'id': 'exec-1',
        'ruleId': 'rule-1',
        'status': 'PARTIAL',
        'test': false,
        'matchedAt': '2026-10-27T12:00:00Z',
        'startedAt': '2026-10-27T12:00:00Z',
        'completedAt': '2026-10-27T12:00:00.150Z',
        'resultDetail': [
          {
            'deviceId': 'd1',
            'action': 'TURN_ON',
            'success': true,
            'status': 'OK',
          },
          {
            'deviceId': 'd2',
            'action': 'TURN_ON',
            'success': false,
            'status': 'OFFLINE',
          },
        ],
      };

      final exec = AutomationExecution.fromJson(json);
      expect(exec.id, 'exec-1');
      expect(exec.ruleId, 'rule-1');
      expect(exec.status, 'PARTIAL');
      expect(exec.executedAt.toUtc(), DateTime.utc(2026, 10, 27, 12));
      expect(exec.durationMs, 150);
      expect(exec.details, '1/2 hành động lỗi');
    });

    test('test run with PREVIEW steps is not reported as failed', () {
      final exec = AutomationExecution.fromJson({
        'id': 'exec-2',
        'ruleId': 'rule-1',
        'status': 'SKIPPED',
        'test': true,
        'matchedAt': '2026-10-27T12:00:00Z',
        'resultDetail': [
          {'action': 'TURN_ON', 'status': 'PREVIEW', 'success': false},
        ],
      });
      expect(exec.isTest, isTrue);
      expect(exec.details, 'Chạy thử · 1 hành động (không gửi lệnh thật)');
    });
  });
}
