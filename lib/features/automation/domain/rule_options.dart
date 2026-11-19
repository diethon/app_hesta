// Danh mục lựa chọn của trình soạn quy tắc, chép từ bản web
// (frontend_hesta/src/components/deviceActionOptions.ts, ConditionCard.tsx,
// EventPickerSheet.tsx, TemplateGrid.tsx) để app và web tạo ra cùng một quy tắc.
import 'package:flutter/material.dart';

import '../../devices/domain/device.dart';

enum ActionValueKind { none, percentage, number, text, color, json }

class ActionOption {
  const ActionOption(this.code, this.label, this.kind, {this.parameterKey});

  final String code;
  final String label;
  final ActionValueKind kind;
  final String? parameterKey;
}

const actionOptions = <ActionOption>[
  ActionOption('TURN_ON', 'Bật nguồn', ActionValueKind.none),
  ActionOption('TURN_OFF', 'Tắt nguồn', ActionValueKind.none),
  ActionOption('TOGGLE', 'Đảo trạng thái bật/tắt', ActionValueKind.none),
  ActionOption('SET_BRIGHTNESS', 'Đặt độ sáng', ActionValueKind.percentage, parameterKey: 'level'),
  ActionOption('SET_RGB', 'Đặt màu RGB', ActionValueKind.color, parameterKey: 'color'),
  ActionOption('SET_COLOR', 'Đổi màu', ActionValueKind.color, parameterKey: 'color'),
  ActionOption('SET_TEMPERATURE', 'Đặt nhiệt độ', ActionValueKind.number, parameterKey: 'temperature'),
  ActionOption('SET_SPEED', 'Đặt tốc độ', ActionValueKind.percentage, parameterKey: 'speed'),
  ActionOption('SET_MODE', 'Đặt chế độ', ActionValueKind.text, parameterKey: 'mode'),
  ActionOption('OPEN', 'Mở cửa', ActionValueKind.none),
  ActionOption('CLOSE', 'Đóng cửa', ActionValueKind.none),
  ActionOption('STOP', 'Dừng cửa', ActionValueKind.none),
  ActionOption('SET_STATE', 'Đặt trạng thái nâng cao', ActionValueKind.json),
];

const _actionsByType = <String, List<String>>{
  'LIGHT': ['TURN_ON', 'TURN_OFF', 'TOGGLE', 'SET_BRIGHTNESS'],
  'LED': ['TURN_ON', 'TURN_OFF', 'TOGGLE', 'SET_BRIGHTNESS'],
  'LED_RGB': ['TURN_ON', 'TURN_OFF', 'TOGGLE', 'SET_BRIGHTNESS', 'SET_RGB', 'SET_COLOR'],
  'FAN': ['TURN_ON', 'TURN_OFF', 'TOGGLE', 'SET_SPEED'],
  'AC': ['TURN_ON', 'TURN_OFF', 'TOGGLE', 'SET_TEMPERATURE', 'SET_MODE', 'SET_SPEED'],
  'AIR_CONDITIONER': ['TURN_ON', 'TURN_OFF', 'TOGGLE', 'SET_TEMPERATURE', 'SET_MODE', 'SET_SPEED'],
  'SOCKET': ['TURN_ON', 'TURN_OFF', 'TOGGLE'],
  'SMART_PLUG': ['TURN_ON', 'TURN_OFF', 'TOGGLE'],
  'GATE': ['OPEN', 'CLOSE', 'STOP'],
  'ROLLING_DOOR': ['OPEN', 'CLOSE', 'STOP'],
  'CURTAIN': ['OPEN', 'CLOSE', 'STOP', 'TURN_ON', 'TURN_OFF', 'TOGGLE'],
};

/// Mã loại thiết bị kiểu backend (LIGHT, AC, GATE…) suy từ rawType hoặc enum của app.
String deviceTypeCode(Device d) {
  final raw = (d.rawType ?? '').toUpperCase();
  if (raw.isNotEmpty) {
    if (raw == 'RGB_LED' || raw == 'RGB' || raw == 'LED_STRIP') return 'LED_RGB';
    if (raw == 'THERMOSTAT') return 'AC';
    return raw;
  }
  return switch (d.type) {
    DeviceType.light => 'LIGHT',
    DeviceType.ledRgb => 'LED_RGB',
    DeviceType.thermostat => 'AC',
    DeviceType.fan => 'FAN',
    DeviceType.speaker => 'SOCKET',
    DeviceType.lock => 'GATE',
    DeviceType.sensor => 'SENSOR',
    DeviceType.camera => 'CAMERA',
  };
}

/// Lệnh hợp lệ cho thiết bị; luôn kèm "nâng cao" như web.
List<ActionOption> deviceActions(Device d) {
  final allowed = {...?_actionsByType[deviceTypeCode(d)], 'SET_STATE'};
  return actionOptions.where((o) => allowed.contains(o.code)).toList();
}

const _sensorTypes = ['SENSOR', 'TEMP_HUMID', 'MOTION', 'SMOKE', 'DOOR_SENSOR', 'WATER_LEAK', 'DHT', 'PIR', 'LDR'];

bool isSensorDevice(Device d) =>
    d.type == DeviceType.sensor || _sensorTypes.any(deviceTypeCode(d).contains);

bool isControllableDevice(Device d) => !isSensorDevice(d) && d.type != DeviceType.camera;

// ── Điều kiện cảm biến ──────────────────────────────────────────────

class SensorAttribute {
  const SensorAttribute(this.key, this.label, this.unit, {this.isBool = false});

  final String key;
  final String label;
  final String unit;
  final bool isBool;
}

const sensorAttributes = <SensorAttribute>[
  SensorAttribute('temperature', 'Nhiệt độ', '°C'),
  SensorAttribute('humidity', 'Độ ẩm', '%'),
  SensorAttribute('motion', 'Chuyển động', '', isBool: true),
  SensorAttribute('light', 'Ánh sáng', 'lux'),
  SensorAttribute('power', 'Công suất', 'W'),
  SensorAttribute('state', 'Trạng thái', '', isBool: true),
];

SensorAttribute? attributeFor(String key) {
  for (final a in sensorAttributes) {
    if (a.key == key.toLowerCase()) return a;
  }
  return null;
}

/// Chỉ số phù hợp với loại cảm biến (giống web).
List<SensorAttribute> attributesFor(Device? d) {
  if (d == null) return sensorAttributes;
  final t = deviceTypeCode(d);
  List<SensorAttribute> only(List<String> keys) =>
      sensorAttributes.where((a) => keys.contains(a.key)).toList();
  if (t.contains('TEMP') || t.contains('DHT')) return only(['temperature', 'humidity']);
  if (t.contains('MOTION') || t.contains('PIR')) return only(['motion']);
  if (t.contains('LIGHT') || t.contains('LDR')) return only(['light']);
  if (t.contains('POWER') || t.contains('ENERGY') || t.contains('SOCKET')) return only(['power', 'state']);
  return sensorAttributes;
}

/// Giá trị đang đo của thiết bị cho chỉ số, để hiện "Hiện tại: …".
String? liveValue(Device? d, String attribute) {
  if (d == null) return null;
  return switch (attribute) {
    'temperature' => d.temperature == null ? null : '${d.temperature}°C',
    'humidity' => d.humidity == null ? null : '${d.humidity}%',
    'power' => d.energyWatts == null ? null : '${d.energyWatts!.round()}W',
    'state' => d.isOn ? 'Bật' : 'Tắt',
    _ => null,
  };
}

/// Chỉ 3 phép so sánh người dùng phổ thông cần (giống web).
const operatorOptions = <(String, String, String)>[
  ('GT', '>', 'Lớn hơn'),
  ('LT', '<', 'Nhỏ hơn'),
  ('EQ', '=', 'Bằng'),
];

// ── Sự kiện ─────────────────────────────────────────────────────────

class SystemEvent {
  const SystemEvent(this.code, this.name, this.description, this.icon);

  final String code;
  final String name;
  final String description;
  final IconData icon;
}

const systemEvents = <SystemEvent>[
  SystemEvent(
    'EVENT',
    'Sự kiện thiết bị (IoT Event)',
    'Phát sinh khi thiết bị trong nhà (công tắc, rèm, khóa, cổng) thay đổi trạng thái và gửi bản tin sự kiện',
    Icons.bolt_rounded,
  ),
  SystemEvent(
    'DEVICE_STATE_CHANGED',
    'Thay đổi trạng thái thiết bị (Realtime)',
    'Sự kiện phát sinh trên luồng realtime khi thiết bị thay đổi trạng thái hoạt động',
    Icons.sensors_rounded,
  ),
];

const eventFriendlyNames = <String, String>{
  'DEVICE_STATE_CHANGED': 'thiết bị thay đổi trạng thái',
  'SECURITY_ALERT': 'có cảnh báo an ninh',
  'SECURITY_EVENT': 'có sự kiện an ninh',
  'GAS_LEAK_DETECTED': 'phát hiện rò rỉ khí gas',
  'DOOR_OPENED': 'cửa mở',
  'GATE_OPENED': 'cổng mở',
  'MANUAL_OVERRIDE': 'điều khiển thủ công thiết bị',
  'MOTION_DETECTED': 'phát hiện chuyển động',
  'EVENT': 'thiết bị gửi sự kiện',
  'SENSOR': 'cảm biến gửi dữ liệu',
};

String eventLabel(String code) {
  final t = eventFriendlyNames[code] ?? code;
  return t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1)}';
}

// ── Màu ─────────────────────────────────────────────────────────────

const colorSwatches = <(String, String)>[
  ('#ff4d4f', 'Đỏ'),
  ('#faad14', 'Vàng'),
  ('#52c41a', 'Xanh lá'),
  ('#1890ff', 'Xanh dương'),
  ('#722ed1', 'Tím'),
  ('#eb2f96', 'Hồng'),
  ('#ffffff', 'Trắng'),
];

Color? parseHex(String? hex) {
  if (hex == null) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  final v = int.tryParse(h, radix: 16);
  return h.length == 6 && v != null ? Color(0xFF000000 | v) : null;
}

/// Tham số màu đầy đủ như web gửi: color, hex và r/g/b.
Map<String, dynamic> colorParams(String hex) {
  final c = parseHex(hex)!;
  return {
    'color': hex,
    'hex': hex,
    'r': (c.r * 255).round(),
    'g': (c.g * 255).round(),
    'b': (c.b * 255).round(),
  };
}

/// Tham số mặc định khi đổi lệnh (giống ActionStepCard của web).
Map<String, dynamic> defaultParamsFor(String code) => switch (code) {
  'SET_BRIGHTNESS' => {'level': 50},
  'SET_RGB' || 'SET_COLOR' => colorParams('#ffc107'),
  'SET_TEMPERATURE' => {'temperature': 26},
  'SET_SPEED' => {'speed': 50},
  'SET_MODE' => {'mode': 'COOL'},
  'SET_STATE' => {'state': 'ON'},
  _ => <String, dynamic>{},
};

const acModes = <(String, String)>[
  ('COOL', 'Làm mát'),
  ('HEAT', 'Sưởi'),
  ('DRY', 'Hút ẩm'),
  ('FAN', 'Quạt'),
  ('AUTO', 'Tự động'),
];

// ── Mẫu tạo nhanh ───────────────────────────────────────────────────

class AutomationTemplate {
  const AutomationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.triggerType,
    required this.icon,
    this.eventCode,
    this.action = 'TURN_ON',
    this.preferDeviceType,
    this.sampleTime,
  });

  final String id;
  final String name;
  final String description;
  final String triggerType;
  final IconData icon;
  final String? eventCode;
  final String action;
  final String? preferDeviceType;
  final TimeOfDay? sampleTime;
}

const automationTemplates = <AutomationTemplate>[
  AutomationTemplate(
    id: 'motion-light',
    name: 'Bật đèn khi có chuyển động',
    description: 'Phát hiện có người, tự động bật đèn chiếu sáng',
    triggerType: 'SENSOR',
    icon: Icons.directions_walk_rounded,
  ),
  AutomationTemplate(
    id: 'door-ac',
    name: 'Tắt điều hòa khi có sự kiện mở cửa',
    description: 'Nhận sự kiện mở cửa, tự động tắt điều hòa tiết kiệm điện',
    triggerType: 'EVENT',
    icon: Icons.door_front_door_outlined,
    eventCode: 'EVENT',
    action: 'TURN_OFF',
  ),
  AutomationTemplate(
    id: 'evening-lights',
    name: 'Bật đèn lúc 18:00',
    description: 'Hằng ngày lúc 18:00, tự động bật đèn phòng khách',
    triggerType: 'SCHEDULE',
    icon: Icons.schedule_rounded,
    preferDeviceType: 'LIGHT',
    sampleTime: TimeOfDay(hour: 18, minute: 0),
  ),
];

/// Kiểm tra trước khi lưu; null = lưu được (giống validateRuleDraft của web).
String? validateRuleDraft({
  required String name,
  required String triggerType,
  required List<({String? deviceId, Object? expectedValue})> conditions,
  required List<({String action, String? deviceId, String? sceneId})> actions,
  required int activeScheduleCount,
}) {
  if (name.trim().isEmpty) return 'Nhập tên quy tắc (tối đa 40 ký tự)';
  if (triggerType == 'SCHEDULE' && activeScheduleCount == 0) return 'Thêm ít nhất 1 giờ chạy';
  if (triggerType == 'SENSOR') {
    if (conditions.isEmpty) return 'Thêm ít nhất 1 điều kiện cho cảm biến';
    if (conditions.any((c) => c.deviceId == null)) return 'Chọn cảm biến nguồn cho điều kiện';
  }
  if (triggerType == 'EVENT' &&
      (conditions.isEmpty || '${conditions.first.expectedValue ?? ''}'.isEmpty)) {
    return 'Chọn sự kiện kích hoạt';
  }
  if (actions.isEmpty) return 'Thêm ít nhất 1 hành động thực thi';
  if (actions.any((a) => a.action == 'EXECUTE_SCENE' ? a.sceneId == null : a.deviceId == null)) {
    return 'Chọn thiết bị hoặc kịch bản cho hành động';
  }
  return null;
}
