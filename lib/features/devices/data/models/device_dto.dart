import '../../domain/device.dart';


/// DTO thích ứng trực tiếp từ DeviceResponse & TwinDeviceSnapshotResponse của backend_hesta.
class DeviceDto {
  const DeviceDto({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    required this.status,
    required this.isOn,
    this.brightness,
    this.temperature,
    this.humidity,
    this.energyWatts,
    this.subtitle,
    this.isFavorite = false,
    this.r,
    this.g,
    this.b,
    this.acMode,
    this.acFan,
    this.acSwing,
    this.timerEnabled,
    this.timerHour,
    this.timerHalfHour,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['deviceId'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final roomId = (json['roomId'] ?? '').toString();
    final rawType = (json['deviceType'] ?? json['type'] ?? 'sensor').toString();
    final rawStatus = (json['status'] ?? 'offline').toString();

    final currentState = json['currentState'] is Map<String, dynamic>
        ? json['currentState'] as Map<String, dynamic>
        : <String, dynamic>{};

    bool isOn = false;
    if (currentState.containsKey('power')) {
      final p = currentState['power'];
      isOn = p == true || p == 'ON' || p == 1 || p == 'true';
    } else if (currentState.containsKey('state')) {
      final st = currentState['state']?.toString().toUpperCase();
      // Với Lock trong app SYNA: isOn = true là "khoá", isOn = false là "mở khoá"
      isOn = st != 'OPEN' && st != 'OPENING' && st != 'UNLOCKED';
    } else if (json.containsKey('isOn')) {
      isOn = json['isOn'] == true;
    }

    int? brightness;
    if (currentState.containsKey('brightness')) {
      brightness = (currentState['brightness'] as num?)?.toInt();
    } else if (currentState.containsKey('level')) {
      brightness = (currentState['level'] as num?)?.toInt();
    } else if (json.containsKey('brightness')) {
      brightness = (json['brightness'] as num?)?.toInt();
    }

    int? temperature;
    if (currentState.containsKey('temperature')) {
      temperature = (currentState['temperature'] as num?)?.round();
    } else if (currentState.containsKey('temp')) {
      temperature = (currentState['temp'] as num?)?.round();
    } else if (json.containsKey('temperature')) {
      temperature = (json['temperature'] as num?)?.round();
    }

    int? humidity;
    if (currentState.containsKey('humidity')) {
      humidity = (currentState['humidity'] as num?)?.round();
    } else if (currentState.containsKey('humid')) {
      humidity = (currentState['humid'] as num?)?.round();
    } else if (json.containsKey('humidity')) {
      humidity = (json['humidity'] as num?)?.round();
    }

    int? r = (currentState['r'] as num?)?.toInt() ?? (json['r'] as num?)?.toInt();
    int? g = (currentState['g'] as num?)?.toInt() ?? (json['g'] as num?)?.toInt();
    int? b = (currentState['b'] as num?)?.toInt() ?? (json['b'] as num?)?.toInt();

    String? acMode = currentState['mode']?.toString() ?? json['mode']?.toString();
    String? acFan = currentState['fan']?.toString() ?? json['fan']?.toString();
    bool? acSwing = currentState['swing'] == true ||
        currentState['swing'] == 'true' ||
        currentState['swing'] == 'ON' ||
        json['swing'] == true;

    bool? timerEnabled = currentState['timerEnabled'] == true || json['timerEnabled'] == true;
    int? timerHour = (currentState['timerHour'] as num?)?.toInt() ??
        (json['timerHour'] as num?)?.toInt() ??
        (currentState['hour'] as num?)?.toInt();
    bool? timerHalfHour = currentState['timerHalfHour'] == true ||
        json['timerHalfHour'] == true ||
        currentState['halfHour'] == true;

    final energyWatts = (currentState['energyWatts'] as num?)?.toDouble() ??
        (json['energyWatts'] as num?)?.toDouble();

    final subtitle = json['roomName'] as String? ??
        json['nodeName'] as String? ??
        json['subtitle'] as String?;

    final isFavorite = json['isFavorite'] == true;

    return DeviceDto(
      id: id,
      name: name,
      roomId: roomId,
      type: rawType,
      status: rawStatus,
      isOn: isOn,
      brightness: brightness,
      temperature: temperature,
      humidity: humidity,
      energyWatts: energyWatts,
      subtitle: subtitle,
      isFavorite: isFavorite,
      r: r,
      g: g,
      b: b,
      acMode: acMode,
      acFan: acFan,
      acSwing: acSwing,
      timerEnabled: timerEnabled,
      timerHour: timerHour,
      timerHalfHour: timerHalfHour,
    );
  }

  final String id;
  final String name;
  final String roomId;
  final String type;
  final String status;
  final bool isOn;
  final int? brightness;
  final int? temperature;
  final int? humidity;
  final double? energyWatts;
  final String? subtitle;
  final bool isFavorite;

  final int? r;
  final int? g;
  final int? b;
  final String? acMode;
  final String? acFan;
  final bool? acSwing;
  final bool? timerEnabled;
  final int? timerHour;
  final bool? timerHalfHour;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roomId': roomId,
    'type': type,
    'status': status,
    'isOn': isOn,
    'brightness': brightness,
    'temperature': temperature,
    'humidity': humidity,
    'energyWatts': energyWatts,
    'subtitle': subtitle,
    'isFavorite': isFavorite,
    'r': r,
    'g': g,
    'b': b,
    'mode': acMode,
    'fan': acFan,
    'swing': acSwing,
    'timerEnabled': timerEnabled,
    'timerHour': timerHour,
    'timerHalfHour': timerHalfHour,
  };

  Device toDomain() {
    return Device(
      id: id,
      name: name,
      roomId: roomId,
      type: _parseDeviceType(type),
      status: _parseDeviceStatus(status),
      isOn: isOn,
      brightness: brightness,
      temperature: temperature,
      humidity: humidity,
      energyWatts: energyWatts,
      subtitle: subtitle,
      isFavorite: isFavorite,
      r: r,
      g: g,
      b: b,
      acMode: acMode,
      acFan: acFan,
      acSwing: acSwing,
      timerEnabled: timerEnabled,
      timerHour: timerHour,
      timerHalfHour: timerHalfHour,
      rawType: type,
    );
  }

  static DeviceType _parseDeviceType(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper.contains('GATE') || upper.contains('ROLLING_DOOR')) {
      return DeviceType.lock;
    }
    return switch (upper) {
      'LED_RGB' || 'RGB_LED' || 'RGB' || 'LED_STRIP' => DeviceType.ledRgb,
      'LIGHT' || 'LED' => DeviceType.light,
      'AC' || 'THERMOSTAT' || 'AIR_CONDITIONER' => DeviceType.thermostat,
      'LOCK' || 'DOOR' => DeviceType.lock,
      'FAN' => DeviceType.fan,
      'SENSOR' || 'TEMP_SENSOR' || 'MOTION_SENSOR' || 'TEMP_HUMID_SENSOR' || 'SMOKE_SENSOR' => DeviceType.sensor,
      'CAMERA' || 'CAMERA_AI' => DeviceType.camera,
      'SPEAKER' || 'SOCKET' || 'SMART_PLUG' => DeviceType.speaker,
      _ => DeviceType.values.asNameMap()[raw.toLowerCase()] ?? DeviceType.sensor,
    };
  }

  static DeviceStatus _parseDeviceStatus(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'ONLINE' || upper == 'ACTIVE') {
      return DeviceStatus.online;
    }
    return DeviceStatus.offline;
  }
}

/// Chuyển DeviceCommand sang cấu trúc command request của backend_hesta:
/// - LED RGB: `POST /api/v1/devices/{deviceId}/command`
///   `{ action: 'POWER_ON'|'POWER_OFF'|'SET_RGB'|'SET_BRIGHTNESS', ... }`
/// - Điều hòa (AC): `POST /api/v1/devices/{deviceId}/air-conditioner/command`
///   `{ action: 'SET_POWER'|'SET_TEMPERATURE'|'TEMPERATURE_PLUS'|'TEMPERATURE_MINUS'|'SET_FAN'|'SET_MODE'|'SET_SWING'|'SET_TIMER'|'CANCEL_TIMER'|'GET_STATE', ... }`
Map<String, dynamic> deviceCommandToRequestBody(DeviceCommand command) {
  // 1. Điều khiển Điều hòa (AC theo iot-ac.http)
  if (command.isAc) {
    if (command.cancelTimer == true) {
      return {'action': 'CANCEL_TIMER'};
    }
    if (command.acAction != null) {
      final body = <String, dynamic>{'action': command.acAction};
      if (command.isOn != null) body['power'] = command.isOn;
      if (command.temperature != null) body['temperature'] = command.temperature;
      if (command.mode != null) body['mode'] = command.mode;
      if (command.fan != null) body['fan'] = command.fan;
      if (command.swing != null) body['swing'] = command.swing;
      if (command.hour != null) body['hour'] = command.hour;
      if (command.halfHour != null) body['halfHour'] = command.halfHour;
      if (command.customParams != null) body.addAll(command.customParams!);
      return body;
    }
    if (command.mode != null) {
      return {'action': 'SET_MODE', 'mode': command.mode};
    }
    if (command.fan != null) {
      return {'action': 'SET_FAN', 'fan': command.fan};
    }
    if (command.swing != null) {
      return {'action': 'SET_SWING', 'swing': command.swing};
    }
    if (command.hour != null) {
      return {
        'action': 'SET_TIMER',
        'hour': command.hour,
        'halfHour': command.halfHour ?? false,
      };
    }
    if (command.temperature != null) {
      return {'action': 'SET_TEMPERATURE', 'temperature': command.temperature};
    }
    if (command.isOn != null) {
      return {'action': 'SET_POWER', 'power': command.isOn};
    }
  }

  // 2. Lệnh chỉnh màu LED_RGB (theo iot-led.http)
  if (command.r != null && command.g != null && command.b != null) {
    return {
      'action': 'SET_RGB',
      'r': command.r,
      'g': command.g,
      'b': command.b,
      'parameters': <String, dynamic>{
        'r': command.r,
        'g': command.g,
        'b': command.b,
        if (command.isOn != null) 'power': command.isOn,
      },
    };
  }

  // 3. Custom Action nếu có
  if (command.customAction != null) {
    final body = <String, dynamic>{'action': command.customAction};
    if (command.customParams != null) {
      body.addAll(command.customParams!);
      body['parameters'] = command.customParams;
    }
    return body;
  }

  // 4. Lệnh tiêu chuẩn (Bảo đảm tương thích 100% với test suite hiện có)
  final hasBrightness = command.brightness != null;
  final hasTemperature = command.temperature != null;
  final hasOn = command.isOn != null;

  if (hasOn && !hasBrightness && !hasTemperature) {
    return {
      'action': command.isOn! ? 'POWER_ON' : 'POWER_OFF',
      'parameters': <String, dynamic>{'power': command.isOn},
    };
  }

  if (hasBrightness && !hasTemperature) {
    return {
      'action': 'SET_BRIGHTNESS',
      'parameters': <String, dynamic>{
        'brightness': command.brightness,
        if (hasOn) 'power': command.isOn,
      },
    };
  }

  if (hasTemperature && !hasBrightness) {
    return {
      'action': 'SET_TEMPERATURE',
      'parameters': <String, dynamic>{
        'temperature': command.temperature,
        if (hasOn) 'power': command.isOn,
      },
    };
  }

  return {
    'action': 'SET_STATE',
    'parameters': <String, dynamic>{
      if (hasOn) 'power': command.isOn,
      if (hasBrightness) 'brightness': command.brightness,
      if (hasTemperature) 'temperature': command.temperature,
    },
  };
}

