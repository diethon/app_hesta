import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/devices/data/models/device_dto.dart';
import 'package:syna/features/devices/domain/device.dart';

void main() {
  group('LED_RGB Device and Commands (iot-led.http)', () {
    test('DeviceDto parse LED_RGB device from backend json', () {
      final json = {
        'id': 'led-001',
        'name': 'Smart Strip',
        'roomId': 'room-001',
        'deviceType': 'LED_RGB',
        'status': 'ONLINE',
        'currentState': {
          'power': 'ON',
          'brightness': 75,
          'r': 255,
          'g': 128,
          'b': 0,
        },
      };

      final dto = DeviceDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.type, DeviceType.ledRgb);
      expect(domain.isOn, isTrue);
      expect(domain.brightness, 75);
      expect(domain.r, 255);
      expect(domain.g, 128);
      expect(domain.b, 0);
      expect(domain.rgbColor, isNotNull);
      expect(domain.rgbColor?.red, 255);
      expect(domain.rgbColor?.green, 128);
      expect(domain.rgbColor?.blue, 0);
    });

    test('deviceCommandToRequestBody creates SET_RGB command', () {
      const command = DeviceCommand(
        r: 0,
        g: 229,
        b: 255,
        isOn: true,
      );

      final body = deviceCommandToRequestBody(command);
      expect(body['action'], 'SET_RGB');
      expect(body['r'], 0);
      expect(body['g'], 229);
      expect(body['b'], 255);
      expect(body['parameters']['r'], 0);
      expect(body['parameters']['g'], 229);
      expect(body['parameters']['b'], 255);
    });

    test('deviceCommandToRequestBody creates SET_BRIGHTNESS command', () {
      const command = DeviceCommand(brightness: 50);

      final body = deviceCommandToRequestBody(command);
      expect(body['action'], 'SET_BRIGHTNESS');
      expect(body['parameters']['brightness'], 50);
    });

    test('deviceCommandToRequestBody creates POWER_ON / POWER_OFF command', () {
      expect(
        deviceCommandToRequestBody(const DeviceCommand(isOn: true)),
        {
          'action': 'POWER_ON',
          'parameters': {'power': true},
        },
      );
      expect(
        deviceCommandToRequestBody(const DeviceCommand(isOn: false)),
        {
          'action': 'POWER_OFF',
          'parameters': {'power': false},
        },
      );
    });
  });

  group('Air Conditioner Device and Commands (iot-ac.http)', () {
    test('DeviceDto parse Air Conditioner device from backend json', () {
      final json = {
        'id': 'ac-001',
        'name': 'Living Room AC',
        'roomId': 'room-001',
        'deviceType': 'AIR_CONDITIONER',
        'status': 'ONLINE',
        'currentState': {
          'power': true,
          'temperature': 24,
          'mode': 'COOL',
          'fan': 'HIGH',
          'swing': true,
          'timerEnabled': true,
          'timerHour': 2,
          'timerHalfHour': true,
        },
      };

      final dto = DeviceDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.type, DeviceType.thermostat);
      expect(domain.isOn, isTrue);
      expect(domain.temperature, 24);
      expect(domain.acMode, 'COOL');
      expect(domain.acFan, 'HIGH');
      expect(domain.acSwing, isTrue);
      expect(domain.timerEnabled, isTrue);
      expect(domain.timerHour, 2);
      expect(domain.timerHalfHour, isTrue);
    });

    test('deviceCommandToRequestBody formats AC commands according to iot-ac.http', () {
      // 1. SET_POWER
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          acAction: 'SET_POWER',
          isOn: true,
        )),
        {'action': 'SET_POWER', 'power': true},
      );

      // 2. SET_TEMPERATURE
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          acAction: 'SET_TEMPERATURE',
          temperature: 26,
        )),
        {'action': 'SET_TEMPERATURE', 'temperature': 26},
      );

      // 3. SET_MODE
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          acAction: 'SET_MODE',
          mode: 'COOL',
        )),
        {'action': 'SET_MODE', 'mode': 'COOL'},
      );

      // 4. SET_FAN
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          acAction: 'SET_FAN',
          fan: 'AUTO',
        )),
        {'action': 'SET_FAN', 'fan': 'AUTO'},
      );

      // 5. SET_SWING
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          acAction: 'SET_SWING',
          swing: true,
        )),
        {'action': 'SET_SWING', 'swing': true},
      );

      // 6. SET_TIMER
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          acAction: 'SET_TIMER',
          hour: 3,
          halfHour: true,
        )),
        {'action': 'SET_TIMER', 'hour': 3, 'halfHour': true},
      );

      // 7. CANCEL_TIMER
      expect(
        deviceCommandToRequestBody(const DeviceCommand(
          isAc: true,
          cancelTimer: true,
        )),
        {'action': 'CANCEL_TIMER'},
      );
    });
  });
}
