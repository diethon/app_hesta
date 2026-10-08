import 'device.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> getDevices();

  Future<Device> getDeviceById(String id);

  Future<Device> updateDeviceState(String id, DeviceCommand command);
}
