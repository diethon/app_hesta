import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/devices/data/device_providers.dart';
import 'package:syna/features/devices/data/mock_device_repository.dart';
import 'package:syna/features/devices/domain/device.dart';

class _OfflineRepository extends MockDeviceRepository {
  @override
  Future<Device> updateDeviceState(String id, DeviceCommand command) async =>
      throw Exception('Thiết bị đang ngoại tuyến hoặc chưa kết nối');
}

void main() {
  test('failed command is reported and keeps the previous state', () async {
    final errors = <String>[];
    final controller = DevicesController(
      _OfflineRepository(),
      onCommandError: errors.add,
    );
    await controller.load();
    final before = controller.state.value!;

    await controller.updateDevice(
      before.first.id,
      const DeviceCommand(customAction: 'VOL_UP'),
    );

    expect(errors, ['Thiết bị đang ngoại tuyến hoặc chưa kết nối']);
    expect(controller.state.value, before);
  });
}
