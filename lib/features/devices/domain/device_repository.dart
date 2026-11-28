import 'device.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> getDevices();

  Future<Device> getDeviceById(String id);

  Future<Device> updateDeviceState(String id, DeviceCommand command);

  Future<Device> updateDeviceConfig(
    String id, {
    String? name,
    String? roomId,
    String? icon,
    double? wattage,
  });

  Future<void> removeDevice(String id);

  Future<Device> cancelDeviceAutomation(String id, {int minutes = 30});

  Future<Device> extendDeviceAutomation(String id, {int minutes = 60});

  Future<Device> resumeDeviceAutomation(String id);

  Future<List<Map<String, dynamic>>> getDeviceOverrideHistory(String id);

  Future<Device> getDeviceHealth(String id);

  Future<DeviceUptimeInfo> getDeviceUptime(String id, {int days = 7});

  Future<List<Map<String, dynamic>>> getDeviceAuditHistory(String id);

  Future<String> exportDeviceAuditExcel(String id, String deviceName);

  Future<String> exportDeviceAuditCsv(String id, String deviceName);

  Future<Device> updateDeviceWattage(String id, double wattage);
}
