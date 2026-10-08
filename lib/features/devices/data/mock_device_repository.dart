import '../domain/device.dart';
import '../domain/device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  final List<Device> _devices = [
    const Device(
      id: 'living-lamp',
      name: 'Living Room Lamp',
      roomId: 'living-room',
      type: DeviceType.light,
      status: DeviceStatus.online,
      isOn: true,
      brightness: 80,
      energyWatts: 9.4,
      subtitle: '80% Brightness',
      isFavorite: true,
    ),
    const Device(
      id: 'living-ceiling',
      name: 'Ceiling Light',
      roomId: 'living-room',
      type: DeviceType.light,
      status: DeviceStatus.online,
      isOn: true,
      brightness: 100,
      energyWatts: 14.5,
      subtitle: '100% Brightness',
    ),
    const Device(
      id: 'living-led-rgb',
      name: 'Smart LED RGB Strip',
      roomId: 'living-room',
      type: DeviceType.ledRgb,
      status: DeviceStatus.online,
      isOn: true,
      brightness: 80,
      r: 76,
      g: 158,
      b: 255,
      energyWatts: 16.5,
      subtitle: 'Color: Neon Blue',
      isFavorite: true,
    ),
    const Device(
      id: 'living-ac',
      name: 'Air Conditioner',
      roomId: 'living-room',
      type: DeviceType.thermostat,
      status: DeviceStatus.online,
      isOn: true,
      temperature: 24,
      acMode: 'COOL',
      acFan: 'AUTO',
      acSwing: true,
      timerEnabled: false,
      timerHour: 0,
      timerHalfHour: false,
      energyWatts: 720,
      subtitle: 'Cooling • 24°C',
    ),
    const Device(
      id: 'living-fan',
      name: 'Ceiling Fan',
      roomId: 'living-room',
      type: DeviceType.fan,
      status: DeviceStatus.online,

      isOn: false,
      energyWatts: 0,
      subtitle: 'Off',
    ),
    const Device(
      id: 'living-motion',
      name: 'Motion Sensor',
      roomId: 'living-room',
      type: DeviceType.sensor,
      status: DeviceStatus.online,
      isOn: true,
      energyWatts: 0.4,
      subtitle: 'No motion',
    ),
    const Device(
      id: 'living-dht22',
      name: 'DHT22 Sensor',
      roomId: 'living-room',
      type: DeviceType.sensor,
      rawType: 'TEMP_HUMID_SENSOR',
      status: DeviceStatus.online,
      isOn: true,
      temperature: 26,
      humidity: 68,
      energyWatts: 0.1,
      subtitle: '26°C - 68%',
    ),
    const Device(
      id: 'bedroom-ac',
      name: 'Bedroom AC',
      roomId: 'bedroom',
      type: DeviceType.thermostat,
      status: DeviceStatus.online,
      isOn: true,
      temperature: 20,
      energyWatts: 680,
      subtitle: 'Cooling to 20°C',
      isFavorite: true,
    ),
    const Device(
      id: 'main-lock',
      name: 'Main Entrance',
      roomId: 'entry',
      type: DeviceType.lock,
      status: DeviceStatus.online,
      isOn: true,
      energyWatts: 1.2,
      subtitle: 'Secured',
      isFavorite: true,
    ),
    const Device(
      id: 'kitchen-speaker',
      name: 'Kitchen Speaker',
      roomId: 'kitchen',
      type: DeviceType.speaker,
      status: DeviceStatus.online,
      isOn: true,
      brightness: 45,
      energyWatts: 12,
      subtitle: 'Morning Jazz Playlist',
      isFavorite: true,
    ),
    const Device(
      id: 'patio-camera',
      name: 'Patio Camera',
      roomId: 'patio',
      type: DeviceType.camera,
      status: DeviceStatus.online,
      isOn: true,
      energyWatts: 6.8,
      subtitle: 'Live',
    ),
    const Device(
      id: 'office-fan',
      name: 'Office Fan',
      roomId: 'office',
      type: DeviceType.fan,
      status: DeviceStatus.offline,
      isOn: false,
      energyWatts: 0,
      subtitle: 'Offline',
    ),
    const Device(
      id: 'garage-door',
      name: 'Garage Door',
      roomId: 'garage',
      type: DeviceType.lock,
      status: DeviceStatus.online,
      isOn: false,
      energyWatts: 0.8,
      subtitle: 'Secured',
      isFavorite: true,
    ),
    const Device(
      id: 'bathroom-light',
      name: 'Bathroom Light',
      roomId: 'bathroom',
      type: DeviceType.light,
      status: DeviceStatus.online,
      isOn: true,
      brightness: 70,
      energyWatts: 7.2,
      subtitle: '70% Brightness',
    ),
    const Device(
      id: 'garden-sprinkler',
      name: 'Sprinklers',
      roomId: 'garden',
      type: DeviceType.sensor,
      status: DeviceStatus.online,
      isOn: true,
      energyWatts: 25.0,
      subtitle: 'Watering Active',
    ),
  ];

  @override
  Future<List<Device>> getDevices() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List<Device>.unmodifiable(_devices);
  }

  @override
  Future<Device> getDeviceById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _devices.firstWhere((device) => device.id == id);
  }

  @override
  Future<Device> updateDeviceState(String id, DeviceCommand command) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _devices.indexWhere((device) => device.id == id);
    if (index == -1) {
      throw StateError('Device not found: $id');
    }
    final current = _devices[index];

    int? nextTemp = command.temperature ?? current.temperature;
    if (command.acAction == 'TEMPERATURE_PLUS') {
      nextTemp = ((current.temperature ?? 24) + 1).clamp(20, 30);
    } else if (command.acAction == 'TEMPERATURE_MINUS') {
      nextTemp = ((current.temperature ?? 24) - 1).clamp(20, 30);
    }

    final updated = current.copyWith(
      isOn: command.isOn,
      brightness: command.brightness,
      temperature: nextTemp,
      r: command.r,
      g: command.g,
      b: command.b,
      acMode: command.mode,
      acFan: command.fan,
      acSwing: command.swing,
      timerEnabled: command.cancelTimer == true
          ? false
          : (command.hour != null ? true : null),
      timerHour: command.cancelTimer == true ? 0 : command.hour,
      timerHalfHour: command.cancelTimer == true ? false : command.halfHour,
    );
    _devices[index] = updated;
    return updated;
  }

}
