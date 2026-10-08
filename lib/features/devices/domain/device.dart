import 'package:flutter/material.dart';

enum DeviceType { light, ledRgb, thermostat, lock, speaker, camera, fan, sensor }

enum DeviceStatus { online, offline }

class Device {
  const Device({
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
    this.rawType,
  });

  final String id;
  final String name;
  final String roomId;
  final DeviceType type;
  final DeviceStatus status;
  final bool isOn;
  final int? brightness;
  final int? temperature;
  final int? humidity;
  final double? energyWatts;
  final String? subtitle;
  final bool isFavorite;

  // Thuộc tính RGB LED
  final int? r;
  final int? g;
  final int? b;

  // Thuộc tính Điều hòa (AC)
  final String? acMode;
  final String? acFan;
  final bool? acSwing;
  final bool? timerEnabled;
  final int? timerHour;
  final bool? timerHalfHour;
  final String? rawType;

  Color? get rgbColor {
    if (r == null || g == null || b == null) return null;
    return Color.fromARGB(255, r!.clamp(0, 255), g!.clamp(0, 255), b!.clamp(0, 255));
  }

  Device copyWith({
    DeviceStatus? status,
    bool? isOn,
    int? brightness,
    int? temperature,
    int? humidity,
    double? energyWatts,
    String? subtitle,
    bool? isFavorite,
    int? r,
    int? g,
    int? b,
    String? acMode,
    String? acFan,
    bool? acSwing,
    bool? timerEnabled,
    int? timerHour,
    bool? timerHalfHour,
    String? rawType,
  }) {
    return Device(
      id: id,
      name: name,
      roomId: roomId,
      type: type,
      status: status ?? this.status,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      energyWatts: energyWatts ?? this.energyWatts,
      subtitle: subtitle ?? this.subtitle,
      isFavorite: isFavorite ?? this.isFavorite,
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      acMode: acMode ?? this.acMode,
      acFan: acFan ?? this.acFan,
      acSwing: acSwing ?? this.acSwing,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerHour: timerHour ?? this.timerHour,
      timerHalfHour: timerHalfHour ?? this.timerHalfHour,
      rawType: rawType ?? this.rawType,
    );
  }
}

class DeviceCommand {
  const DeviceCommand({
    this.isOn,
    this.brightness,
    this.temperature,
    this.r,
    this.g,
    this.b,
    this.isAc = false,
    this.acAction,
    this.mode,
    this.fan,
    this.swing,
    this.hour,
    this.halfHour,
    this.cancelTimer,
    this.customAction,
    this.customParams,
  });

  final bool? isOn;
  final int? brightness;
  final int? temperature;

  // LED RGB
  final int? r;
  final int? g;
  final int? b;

  // Air Conditioner
  final bool isAc;
  final String? acAction;
  final String? mode;
  final String? fan;
  final bool? swing;
  final int? hour;
  final bool? halfHour;
  final bool? cancelTimer;
  final String? customAction;
  final Map<String, dynamic>? customParams;
}

