enum OnboardingStep {
  scanQr,
  verifyDevice,
  bleScanning,
  bleConnected,
  wifiProvisioning,
  mqttConnecting,
  homeRoomSelection,
  claiming,
  completed,
  error,
}

class DevicePreview {
  const DevicePreview({
    required this.deviceId,
    required this.name,
    required this.deviceType,
    this.model,
    this.serialNumber,
    required this.status,
  });

  final String deviceId;
  final String name;
  final String deviceType;
  final String? model;
  final String? serialNumber;
  final String status;

  factory DevicePreview.fromJson(Map<String, dynamic> json) {
    return DevicePreview(
      deviceId: (json['deviceId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Thiết bị mới').toString(),
      deviceType: (json['deviceType'] ?? 'LIGHT').toString(),
      model: json['model']?.toString(),
      serialNumber: json['serialNumber']?.toString(),
      status: (json['status'] ?? 'UNCLAIMED').toString(),
    );
  }
}

class BleDiscoveredDevice {
  const BleDiscoveredDevice({
    required this.name,
    required this.id,
    required this.rssi,
  });

  final String name;
  final String id;
  final int rssi;
}

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.scanQr,
    this.token,
    this.preview,
    this.selectedBleDevice,
    this.wifiSsid,
    this.wifiConnected = false,
    this.mqttConnected = false,
    this.deviceRegistered = false,
    this.selectedHomeId,
    this.selectedRoomId,
    this.customDeviceName,
    this.errorMessage,
    this.isLoading = false,
  });

  final OnboardingStep step;
  final String? token;
  final DevicePreview? preview;
  final BleDiscoveredDevice? selectedBleDevice;
  final String? wifiSsid;
  final bool wifiConnected;
  final bool mqttConnected;
  final bool deviceRegistered;
  final String? selectedHomeId;
  final String? selectedRoomId;
  final String? customDeviceName;
  final String? errorMessage;
  final bool isLoading;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? token,
    DevicePreview? preview,
    BleDiscoveredDevice? selectedBleDevice,
    String? wifiSsid,
    bool? wifiConnected,
    bool? mqttConnected,
    bool? deviceRegistered,
    String? selectedHomeId,
    String? selectedRoomId,
    String? customDeviceName,
    String? errorMessage,
    bool? isLoading,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      token: token ?? this.token,
      preview: preview ?? this.preview,
      selectedBleDevice: selectedBleDevice ?? this.selectedBleDevice,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiConnected: wifiConnected ?? this.wifiConnected,
      mqttConnected: mqttConnected ?? this.mqttConnected,
      deviceRegistered: deviceRegistered ?? this.deviceRegistered,
      selectedHomeId: selectedHomeId ?? this.selectedHomeId,
      selectedRoomId: selectedRoomId ?? this.selectedRoomId,
      customDeviceName: customDeviceName ?? this.customDeviceName,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
