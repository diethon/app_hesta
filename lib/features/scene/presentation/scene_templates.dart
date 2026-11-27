// Mẫu tạo nhanh khi tạo kịch bản, chép từ web (frontend_hesta/src/components/scene/sceneTemplates.ts).
// Mỗi mẫu chọn thiết bị phù hợp có trong nhà.
import '../../automation/domain/rule_options.dart' show isControllableDevice;
import '../../devices/domain/device.dart';
import '../domain/scene.dart';

class SceneTemplate {
  const SceneTemplate({
    required this.key,
    required this.name,
    required this.icon,
    required this.description,
  });

  final String key;
  final String name;

  /// Khoá icon lưu lên backend, giống web.
  final String icon;
  final String description;
}

const sceneTemplates = <SceneTemplate>[
  SceneTemplate(
    key: 'morning',
    name: 'Chào buổi sáng',
    icon: 'sun',
    description: 'Bật đèn, mở cổng đón ngày mới',
  ),
  SceneTemplate(
    key: 'night',
    name: 'Chúc ngủ ngon',
    icon: 'moon',
    description: 'Tắt đèn, khóa cửa và tiết kiệm điện',
  ),
  SceneTemplate(
    key: 'away',
    name: 'Rời khỏi nhà',
    icon: 'door',
    description: 'Tắt toàn bộ thiết bị khi ra ngoài',
  ),
  SceneTemplate(
    key: 'home',
    name: 'Về đến nhà',
    icon: 'home',
    description: 'Bật đèn và khởi động điều hòa',
  ),
];

String _typeOf(Device d) => (d.rawType ?? '').toUpperCase();
bool _isLight(Device d) =>
    _typeOf(d).contains('LIGHT') || _typeOf(d).contains('LED');
bool _isAc(Device d) => _typeOf(d).contains('AC') || _typeOf(d).contains('AIR');
bool _isGate(Device d) =>
    _typeOf(d).contains('GATE') || _typeOf(d).contains('DOOR');

/// Các bước của mẫu [key] với thiết bị trong nhà; nhà không có thiết bị của mẫu thì dùng thiết bị điều khiển được đầu tiên.
List<SceneAction> buildSceneTemplateActions(String key, List<Device> devices) {
  final controllable = devices.where(isControllableDevice).toList();
  Device? first(bool Function(Device) test) =>
      controllable.where(test).firstOrNull;

  final steps = <(Device, String)>[];
  void step(Device? d, String action) {
    if (d != null) steps.add((d, action));
  }

  void orFirst(String fallbackAction) {
    if (steps.isEmpty) step(controllable.firstOrNull, fallbackAction);
  }

  switch (key) {
    case 'morning':
      step(first(_isLight), 'TURN_ON');
      step(first(_isGate), 'OPEN');
      orFirst('TURN_ON');
    case 'night':
      step(first(_isLight), 'TURN_OFF');
      step(first(_isGate), 'CLOSE');
      orFirst('TURN_OFF');
    case 'away':
      for (final d in controllable.take(3)) {
        step(d, 'TURN_OFF');
      }
    case 'home':
      step(first(_isLight), 'TURN_ON');
      step(first(_isAc), 'TURN_ON');
      orFirst('TURN_ON');
  }

  final stamp = DateTime.now().millisecondsSinceEpoch;
  return [
    for (var i = 0; i < steps.length; i++)
      SceneAction(
        id: 'temp-$stamp-$i',
        targetDeviceId: steps[i].$1.id,
        targetDeviceName: steps[i].$1.name,
        action: steps[i].$2,
        order: i,
      ),
  ];
}
