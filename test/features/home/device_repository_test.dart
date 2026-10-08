import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/devices/data/mock_device_repository.dart';
import 'package:syna/features/devices/domain/device.dart';

void main() {
  test('updates device power state outside widgets', () async {
    final repository = MockDeviceRepository();

    final updated = await repository.updateDeviceState(
      'living-lamp',
      const DeviceCommand(isOn: false),
    );

    expect(updated.isOn, isFalse);
  });
}
