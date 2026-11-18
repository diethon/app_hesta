import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/devices/domain/device.dart';

void main() {
  group('Device Manual Override & Health Domain Tests', () {
    test(
      'isOverrideActive returns true when override until is in the future',
      () {
        final futureTime = DateTime.now().add(const Duration(minutes: 25));
        final device = Device(
          id: 'dev-1',
          name: 'Living Room Light',
          roomId: 'room-1',
          type: DeviceType.light,
          status: DeviceStatus.online,
          isOn: true,
          manualOverrideUntil: futureTime.toIso8601String(),
          manualOverrideActive: false,
        );

        expect(device.isOverrideActive, isTrue);
        expect(device.formattedOverrideTime, isNotNull);
        expect(device.formattedOverrideTime.contains(':'), isTrue);
      },
    );

    test(
      'isOverrideActive returns true when manualOverrideActive is explicitly true',
      () {
        const device = Device(
          id: 'dev-2',
          name: 'AC Unit',
          roomId: 'room-2',
          type: DeviceType.thermostat,
          status: DeviceStatus.online,
          isOn: true,
          manualOverrideActive: true,
        );

        expect(device.isOverrideActive, isTrue);
      },
    );

    test('isOverrideActive returns false when no override set or expired', () {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 5));
      final device = Device(
        id: 'dev-3',
        name: 'Fan',
        roomId: 'room-3',
        type: DeviceType.fan,
        status: DeviceStatus.online,
        isOn: false,
        manualOverrideUntil: pastTime.toIso8601String(),
        manualOverrideActive: false,
      );

      expect(device.isOverrideActive, isFalse);
    });

    test('Relay health and chattering properties are calculated properly', () {
      const healthyDevice = Device(
        id: 'dev-4',
        name: 'Relay Switch 1',
        roomId: 'room-1',
        type: DeviceType.light,
        status: DeviceStatus.online,
        isOn: true,
        switchCycles: 15000,
        maxRatedCycles: 100000,
        uptimePercent: 99.8,
        chatteringWarning: false,
        safetyTripped: false,
      );

      expect(healthyDevice.calculatedHealthPercent, 85.0);
      expect(healthyDevice.chatteringWarning, isFalse);

      const wornDevice = Device(
        id: 'dev-5',
        name: 'Worn Relay',
        roomId: 'room-2',
        type: DeviceType.light,
        status: DeviceStatus.online,
        isOn: false,
        switchCycles: 95000,
        maxRatedCycles: 100000,
        uptimePercent: 92.5,
        chatteringWarning: true,
        safetyTripped: true,
      );

      expect(wornDevice.calculatedHealthPercent, 5.0);
      expect(wornDevice.chatteringWarning, isTrue);
      expect(wornDevice.safetyTripped, isTrue);
    });
  });
}
