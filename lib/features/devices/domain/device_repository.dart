import 'device.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> getDevices();

  Future<Device> getDeviceById(String id);

  Future<Device> updateDeviceState(String id, DeviceCommand command);

  Future<Device> cancelDeviceAutomation(String id, {int minutes = 30});

  Future<Device> resumeDeviceAutomation(String id);

  Future<Device> getDeviceHealth(String id);
}
