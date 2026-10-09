import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_provisioning_service.dart';
import '../data/device_onboarding_repository.dart';
import '../domain/device_onboarding_models.dart';

final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>((ref) {
  final repository = ref.watch(deviceOnboardingRepositoryProvider);
  final bleService = ref.watch(bleProvisioningServiceProvider);
  return OnboardingController(repository, bleService);
});

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._repository, this._bleService)
      : super(const OnboardingState());

  final DeviceOnboardingRepository _repository;
  final BleProvisioningService _bleService;

  List<BleDiscoveredDevice> discoveredBleDevices = [];

  String? extractTokenFromQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.parse(trimmed);
      final tokenParam = uri.queryParameters['token'];
      if (tokenParam != null && tokenParam.isNotEmpty) {
        return tokenParam;
      }
    } catch (_) {}

    // Fallback: If formatted as syna://device/register?token=...
    if (trimmed.contains('token=')) {
      final parts = trimmed.split('token=');
      if (parts.length > 1) {
        final token = parts[1].split('&').first.trim();
        if (token.isNotEmpty) return token;
      }
    }

    // Direct token string fallback
    return trimmed;
  }

  Future<void> onQrScanned(String rawQr) async {
    final token = extractTokenFromQr(rawQr);
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        step: OnboardingStep.error,
        errorMessage: 'Mã QR không đúng định dạng của SYNA Smart Home.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, token: token, errorMessage: null);

    try {
      final preview = await _repository.resolveQrToken(token);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        preview: preview,
        customDeviceName: preview.name,
        step: OnboardingStep.verifyDevice,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        step: OnboardingStep.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> confirmDevice() async {
    state = state.copyWith(
      step: OnboardingStep.bleScanning,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final devices = await _bleService.scanForDevices();
      if (!mounted) return;
      discoveredBleDevices = devices;

      if (devices.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          selectedBleDevice: null,
          errorMessage: 'Không tìm thấy thiết bị ESP32 (SYNA-ESP32S3). Hãy đảm bảo ESP32 đã cấp nguồn và ở gần điện thoại.',
        );
        return;
      }

      final target = devices.firstWhere(
        (d) => d.name.contains('SYNA') || d.name.contains('ESP32'),
        orElse: () => devices.first,
      );

      state = state.copyWith(
        isLoading: false,
        selectedBleDevice: target,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        step: OnboardingStep.error,
        errorMessage: 'Lỗi khi quét Bluetooth: ${e.toString().replaceFirst("Exception: ", "")}',
      );
    }
  }

  Future<void> connectBleDevice(BleDiscoveredDevice device) async {
    state = state.copyWith(
      isLoading: true,
      selectedBleDevice: device,
      errorMessage: null,
    );

    try {
      await _bleService.connect(device);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        step: OnboardingStep.wifiProvisioning,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        step: OnboardingStep.error,
        errorMessage: 'Không thể kết nối Bluetooth tới thiết bị: ${e.toString().replaceFirst("Exception: ", "")}',
      );
    }
  }

  Future<void> submitWifiCredentials(String ssid, String password) async {
    if (ssid.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập tên Wi-Fi (SSID)');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      wifiSsid: ssid.trim(),
      wifiConnected: false,
      mqttConnected: false,
      errorMessage: null,
    );

    try {
      // Step 2 & 3: BLE Single JSON provision & listen for real ESP32 response stream
      await _bleService.provisionWifi(
        ssid: ssid.trim(),
        password: password,
        onWifiConnected: () {
          if (!mounted) return;
          state = state.copyWith(
            wifiConnected: true,
            step: OnboardingStep.mqttConnecting,
          );
        },
        onMqttConnected: () {
          if (!mounted) return;
          state = state.copyWith(
            mqttConnected: true,
            deviceRegistered: true,
          );
        },
      );

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        wifiConnected: true,
        mqttConnected: true,
        deviceRegistered: true,
        step: OnboardingStep.homeRoomSelection,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        wifiConnected: false,
        mqttConnected: false,
        step: OnboardingStep.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void updateSelectedHomeAndRoom({String? homeId, String? roomId, String? customName}) {
    state = state.copyWith(
      selectedHomeId: homeId ?? state.selectedHomeId,
      selectedRoomId: roomId ?? state.selectedRoomId,
      customDeviceName: customName ?? state.customDeviceName,
    );
  }

  Future<void> claimDevice() async {
    final preview = state.preview;
    final token = state.token;
    final homeId = state.selectedHomeId;
    final roomId = state.selectedRoomId;

    if (preview == null || token == null) {
      state = state.copyWith(errorMessage: 'Thiếu thông tin xác thực thiết bị.');
      return;
    }

    if (homeId == null || homeId.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng chọn Nhà');
      return;
    }

    if (roomId == null || roomId.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng chọn Phòng');
      return;
    }

    state = state.copyWith(
      step: OnboardingStep.claiming,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final nodeCode = state.selectedBleDevice?.name.contains('ESP') == true
          ? 'esp32-001'
          : 'esp32-001';

      await _repository.claimDevice(
        deviceId: preview.deviceId,
        token: token,
        homeId: homeId,
        roomId: roomId,
        name: state.customDeviceName ?? preview.name,
        nodeCode: nodeCode,
      );

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        step: OnboardingStep.completed,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        step: OnboardingStep.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void retry() {
    if (state.selectedBleDevice != null && state.token != null) {
      state = state.copyWith(
        step: OnboardingStep.wifiProvisioning,
        isLoading: false,
        errorMessage: null,
        wifiConnected: false,
        mqttConnected: false,
      );
    } else {
      _bleService.disconnect();
      state = const OnboardingState();
    }
  }

  void reset() {
    _bleService.disconnect();
    state = const OnboardingState();
  }
}
