import 'package:flutter_test/flutter_test.dart';
import 'package:syna/core/widgets/studio.dart';
import 'package:syna/features/automation/domain/automation_models.dart';
import 'package:syna/features/automation/domain/rule_options.dart';
import 'package:syna/features/automation/presentation/rule_editor_parts.dart';
import 'package:syna/features/devices/domain/device.dart';

void main() {
  String? check({
    String name = 'Quy tắc',
    String trigger = 'SENSOR',
    List<({String? deviceId, String? groupId, Object? expectedValue})> conds =
        const [(deviceId: 's1', groupId: null, expectedValue: 30)],
    List<
      ({
        String action,
        String? deviceId,
        String? sceneId,
        String? groupId,
        Object? seconds,
      })
    >
    acts = const [
      (
        action: 'TURN_ON',
        deviceId: 'd1',
        sceneId: null,
        groupId: null,
        seconds: null,
      ),
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
    expect(
      check(conds: const [(deviceId: null, groupId: null, expectedValue: 1)]),
      'Chọn thiết bị hoặc nhóm cho điều kiện',
    );
    expect(
      check(
        trigger: 'EVENT',
        conds: const [(deviceId: null, groupId: null, expectedValue: '')],
      ),
      'Chọn sự kiện kích hoạt',
    );
    expect(check(acts: const []), 'Thêm ít nhất 1 hành động thực thi');
    expect(
      check(
        acts: const [
          (
            action: 'EXECUTE_SCENE',
            deviceId: null,
            sceneId: null,
            groupId: null,
            seconds: null,
          ),
        ],
      ),
      'Chọn thiết bị, nhóm hoặc kịch bản cho hành động',
    );
  });

  test('group and wait steps are validated like the web', () {
    const turnOn = (
      action: 'TURN_ON',
      deviceId: 'd1',
      sceneId: null,
      groupId: null,
      seconds: null,
    );
    ({
      String action,
      String? deviceId,
      String? sceneId,
      String? groupId,
      Object? seconds,
    })
    wait(Object s) => (
      action: kDelayAction,
      deviceId: null,
      sceneId: null,
      groupId: null,
      seconds: s,
    );
    expect(
      check(conds: const [(deviceId: null, groupId: '', expectedValue: 30)]),
      'Chọn thiết bị hoặc nhóm cho điều kiện',
    );
    expect(
      check(conds: const [(deviceId: null, groupId: 'g1', expectedValue: 30)]),
      isNull,
    );
    expect(check(acts: [wait(5)]), 'Thêm ít nhất 1 hành động ngoài bước chờ');
    expect(
      check(acts: [turnOn, wait(0)]),
      'Chọn thiết bị, nhóm hoặc kịch bản cho hành động',
    );
    expect(check(acts: [turnOn, wait(30)]), isNull);
    expect(
      check(
        acts: const [
          (
            action: 'TURN_ON',
            deviceId: null,
            sceneId: null,
            groupId: '',
            seconds: null,
          ),
        ],
      ),
      'Chọn thiết bị, nhóm hoặc kịch bản cho hành động',
    );
  });

  test('durations and step sentences read the same as the web', () {
    expect(formatDuration(45), '45 giây');
    expect(formatDuration(120), '2 phút');
    expect(formatDuration(5400), '1 giờ 30 phút');
    expect(autoOffVerb('TURN_ON'), 'Tự tắt');
    expect(autoOffVerb('OPEN'), 'Tự đóng');
    expect(autoOffVerb('TURN_OFF'), isNull);
    expect(
      actionSentence(
        const RuleAction(action: kDelayAction, parameters: {'seconds': 90}),
        null,
        null,
      ),
      'Chờ 1 phút 30 giây',
    );
    expect(
      actionSentence(
        const RuleAction(
          action: 'TURN_ON',
          groupId: 'g',
          groupName: 'Tầng 1',
          parameters: {kAutoOffKey: 300},
        ),
        null,
        null,
      ),
      'Bật nhóm Tầng 1, tự tắt sau 5 phút',
    );
    const anyMember = RuleCondition(
      attribute: 'power',
      operator: 'EQ',
      expectedValue: 'ON',
      groupId: 'g',
      groupName: 'Đèn',
    );
    expect(
      conditionSentence(anyMember, null),
      'một thiết bị trong nhóm Đèn đang bật',
    );
  });

  test('a rule round-trips group, wait and hold fields', () {
    final rule = AutomationRule.fromJson({
      'id': 'r',
      'homeId': 'h',
      'name': 'n',
      'holdSeconds': 30,
      'conditions': [
        {
          'groupId': 'g',
          'groupName': 'Đèn',
          'attribute': 'power',
          'operator': 'EQ',
          'expectedValue': 'ON',
        },
      ],
      'actions': [
        {
          'groupId': 'g2',
          'action': 'TURN_ON',
          'parameters': {kAutoOffKey: 60},
        },
        {
          'action': kDelayAction,
          'parameters': {'seconds': 5},
        },
      ],
    });
    final json = rule.toJson();
    expect(json['holdSeconds'], 30);
    expect((json['conditions'] as List).first['groupId'], 'g');
    expect((json['actions'] as List).first['groupId'], 'g2');
    expect((json['actions'] as List).last['parameters'], {'seconds': 5});
  });

  test('describeAction never shows raw parameter keys', () {
    expect(
      describeAction('SET_BRIGHTNESS', params: {'level': 50}),
      'Độ sáng 50%',
    );
    expect(describeAction('SET_SPEED', params: {'speed': 40}), 'Tốc độ 40%');
    expect(
      describeAction('SET_RGB', params: colorParams('#ff4d4f')),
      'Đổi màu đỏ',
    );
    expect(
      describeAction('TURN_ON', params: {'temperature': 26}),
      'Bật · Nhiệt độ 26°C',
    );
  });

  test('conditionSentence reads like the web', () {
    const motion = RuleCondition(
      attribute: 'motion',
      operator: 'EQ',
      expectedValue: true,
      deviceName: 'PIR',
    );
    expect(conditionSentence(motion, null), 'PIR phát hiện có người');
    const temp = RuleCondition(
      attribute: 'temperature',
      operator: 'GT',
      expectedValue: 30,
      deviceName: 'DHT',
    );
    expect(conditionSentence(temp, null), 'nhiệt độ ở DHT lớn hơn 30°C');
  });

  test('schedule rules say when they run', () {
    final rule = AutomationRule.fromJson({
      'id': 'r',
      'homeId': 'h',
      'name': 'n',
      'triggerType': 'SCHEDULE',
      'schedules': [
        {'scheduledTime': '18:00:00', 'repeatDays': <int>[], 'active': true},
        {
          'scheduledTime': '22:30:00',
          'repeatDays': [6, 7],
          'active': true,
        },
      ],
    });
    expect(
      scheduleSentence(rule.schedules),
      'Hằng ngày lúc 18:00 (+1 giờ khác)',
    );
    expect(scheduleSentence(const []), 'Chưa có giờ chạy nào đang bật');
  });

  test('deviceActions follows backend capabilities like the web', () {
    Device device(String type, [Map<String, List<String>>? caps]) => Device(
      id: 'd',
      name: 'd',
      roomId: 'r',
      type: DeviceType.light,
      status: DeviceStatus.online,
      isOn: false,
      rawType: type,
      capabilities: caps,
    );
    List<String> codes(Device d) =>
        deviceActions(d).map((o) => o.code).toList();

    // No capabilities: falls back to the device type.
    expect(codes(device('FAN')), [
      'TURN_ON',
      'TURN_OFF',
      'TOGGLE',
      'SET_SPEED',
    ]);
    // Capabilities win over the type and expand group names.
    expect(codes(device('LED_RGB', {'POWER': [], 'COLOR': []})), [
      'TURN_ON',
      'TURN_OFF',
      'TOGGLE',
      'SET_RGB',
      'SET_COLOR',
    ]);
    // A plain light never offers colour, even if declared.
    expect(
      codes(
        device('LIGHT', {
          'POWER': ['TURN_ON'],
          'COLOR': ['SET_RGB'],
        }),
      ),
      ['TURN_ON'],
    );
  });
}
