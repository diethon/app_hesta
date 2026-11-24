import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/scene/domain/scene.dart';

void main() {
  const scene = Scene(id: 's', homeId: 'h', name: 'Đi ngủ', actions: [
    SceneAction(id: '1', targetDeviceId: 'a', targetDeviceName: 'Đèn bếp', action: 'TURN_OFF', order: 0),
    SceneAction(id: '2', targetDeviceId: 'b', targetDeviceName: 'Quạt', action: 'TURN_OFF', order: 1),
  ]);
  SceneExecution run(String status, List<SceneExecutionDetail> rows) =>
      SceneExecution(id: 'r', sceneId: 's', triggerSource: 'MANUAL', status: status, startedAt: DateTime(2026), resultDetail: rows);
  SceneExecutionDetail ok(String id) => SceneExecutionDetail(deviceId: id, action: 'TURN_OFF', success: true, status: 'SUCCESS');
  SceneExecutionDetail offline(String id) => SceneExecutionDetail(
    deviceId: id, action: 'TURN_OFF', success: false, status: 'FAILED', errorCode: 'DEVICE_OFFLINE', message: 'x');

  test('names the failed devices and why, same as the web', () {
    expect(sceneRunMessage(scene, run('SUCCESS', [ok('a'), ok('b')])), isNull);
    expect(sceneRunMessage(scene, run('FAILED', [offline('a'), offline('b')])),
        'Không chạy được "Đi ngủ": Đèn bếp, Quạt đang ngoại tuyến');
    expect(sceneRunMessage(scene, run('PARTIAL', [ok('a'), offline('b')])),
        '"Đi ngủ" chạy được 1/2 thiết bị. Quạt đang ngoại tuyến');
  });
}
