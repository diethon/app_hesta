import 'package:flutter_test/flutter_test.dart';
import 'package:syna/core/widgets/studio.dart';
import 'package:syna/features/automation/domain/automation_models.dart';
import 'package:syna/features/automation/domain/rule_options.dart';
import 'package:syna/features/automation/presentation/rule_editor_parts.dart';

void main() {
  String? check({
    String name = 'Quy tắc',
    String trigger = 'SENSOR',
    List<({String? deviceId, Object? expectedValue})> conds = const [(deviceId: 's1', expectedValue: 30)],
    List<({String action, String? deviceId, String? sceneId})> acts = const [
      (action: 'TURN_ON', deviceId: 'd1', sceneId: null),
    ],
    int schedules = 0,
  }) => validateRuleDraft(
    name: name,
    triggerType: trigger,
    conditions: conds,
    actions: acts,
    activeScheduleCount: schedules,
  );

  test('validateRuleDraft gives the web messages', () {
    expect(check(), isNull);
    expect(check(name: ' '), 'Nhập tên quy tắc (tối đa 40 ký tự)');
    expect(check(trigger: 'SCHEDULE'), 'Thêm ít nhất 1 giờ chạy');
    expect(check(trigger: 'SCHEDULE', schedules: 1), isNull);
    expect(check(conds: const []), 'Thêm ít nhất 1 điều kiện cho cảm biến');
    expect(check(conds: const [(deviceId: null, expectedValue: 1)]), 'Chọn cảm biến nguồn cho điều kiện');
    expect(check(trigger: 'EVENT', conds: const [(deviceId: null, expectedValue: '')]), 'Chọn sự kiện kích hoạt');
    expect(check(acts: const []), 'Thêm ít nhất 1 hành động thực thi');
    expect(
      check(acts: const [(action: 'EXECUTE_SCENE', deviceId: null, sceneId: null)]),
      'Chọn thiết bị hoặc kịch bản cho hành động',
    );
  });

  test('describeAction never shows raw parameter keys', () {
    expect(describeAction('SET_BRIGHTNESS', params: {'level': 50}), 'Độ sáng 50%');
    expect(describeAction('SET_SPEED', params: {'speed': 40}), 'Tốc độ 40%');
    expect(describeAction('SET_RGB', params: colorParams('#ff4d4f')), 'Đổi màu đỏ');
    expect(describeAction('TURN_ON', params: {'temperature': 26}), 'Bật · Nhiệt độ 26°C');
  });

  test('conditionSentence reads like the web', () {
    const motion = RuleCondition(attribute: 'motion', operator: 'EQ', expectedValue: true, deviceName: 'PIR');
    expect(conditionSentence(motion, null), 'PIR phát hiện có người');
    const temp = RuleCondition(attribute: 'temperature', operator: 'GT', expectedValue: 30, deviceName: 'DHT');
    expect(conditionSentence(temp, null), 'nhiệt độ ở DHT lớn hơn 30°C');
  });
}
