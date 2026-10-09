import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/device_onboarding_models.dart';

class BleConstants {
  static const String deviceName = 'SYNA-ESP32S3';
  // 1 Service UUID duy nhất
  static const String serviceUuid = '12345678-1234-1234-1234-123456789000';
  // 1 Characteristic UUID duy nhất cho cả Ghi cấu hình (Write) và Nhận phản hồi trạng thái (Notify)
  static const String commCharUuid = '12345678-1234-1234-1234-123456789001';
}

abstract interface class BleProvisioningService {
  Future<List<BleDiscoveredDevice>> scanForDevices({Duration timeout = const Duration(seconds: 4)});

  Future<void> connect(BleDiscoveredDevice device);

  Future<void> provisionWifi({
    required String ssid,
    required String password,
    void Function()? onWifiConnected,
    void Function()? onMqttConnected,
  });

  void disconnect();
}

/// Triển khai BLE thực tế kết nối phần cứng ESP32-S3 qua flutter_blue_plus
class FlutterBleProvisioningService implements BleProvisioningService {
  final Map<String, BluetoothDevice> _scanCache = {};
  BluetoothDevice? _connectedBluetoothDevice;
  BluetoothCharacteristic? _commCharacteristic;
  StreamSubscription? _notifySubscription;

  @override
  Future<List<BleDiscoveredDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      debugPrint('[BLE] Thiết bị không hỗ trợ Bluetooth phần cứng.');
      return const [];
    }

    // 1. Kiểm tra trạng thái Bluetooth và yêu cầu bật nếu đang tắt
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.off) {
      debugPrint('[BLE] Bluetooth đang tắt. Yêu cầu bật Bluetooth...');
      try {
        await FlutterBluePlus.turnOn();
        adapterState = await FlutterBluePlus.adapterState.firstWhere(
          (s) => s == BluetoothAdapterState.on,
          orElse: () => BluetoothAdapterState.off,
        );
      } catch (e) {
        debugPrint('[BLE] Không thể bật Bluetooth tự động: $e');
      }
    }

    if (adapterState != BluetoothAdapterState.on) {
      throw Exception('Vui lòng bật Bluetooth trên điện thoại để tìm kiếm thiết bị.');
    }

    // 2. Bắt đầu quét BLE thực tế
    final List<BleDiscoveredDevice> discovered = [];
    final targetGuid = Guid(BleConstants.serviceUuid);
    _scanCache.clear();

    final scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final advName = r.advertisementData.advName;
        final devName = r.device.advName;
        final name = advName.isNotEmpty ? advName : devName;

        final hasService = r.advertisementData.serviceUuids.contains(targetGuid);
        final isSynaOrEsp = name.contains('SYNA') ||
            name.contains('ESP32') ||
            hasService;

        if (isSynaOrEsp) {
          _scanCache[r.device.remoteId.str] = r.device;
          final existingIdx = discovered.indexWhere((d) => d.id == r.device.remoteId.str);
          final item = BleDiscoveredDevice(
            name: name.isNotEmpty ? name : BleConstants.deviceName,
            id: r.device.remoteId.str,
            rssi: r.rssi,
          );
          if (existingIdx >= 0) {
            discovered[existingIdx] = item;
          } else {
            discovered.add(item);
          }
        }
      }
    });

    try {
      // Quét không lọc service UUID trực tiếp trong startScan để tránh việc Android lọc mất
      // do ESP32 để 128-bit UUID trong scan response packet
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );
      // Chờ cho đến khi quá trình quét hoàn tất
      await FlutterBluePlus.isScanning.where((val) => !val).first;
    } finally {
      await scanSubscription.cancel();
    }

    // Kiểm tra thêm kết quả cuối cùng từ scanResults buffer
    try {
      final lastResults = await FlutterBluePlus.scanResults.first;
      for (final r in lastResults) {
        final advName = r.advertisementData.advName;
        final devName = r.device.advName;
        final name = advName.isNotEmpty ? advName : devName;
        final hasService = r.advertisementData.serviceUuids.contains(targetGuid);
        final isSynaOrEsp = name.contains('SYNA') ||
            name.contains('ESP32') ||
            hasService;

        if (isSynaOrEsp) {
          _scanCache[r.device.remoteId.str] = r.device;
          if (!discovered.any((d) => d.id == r.device.remoteId.str)) {
            discovered.add(BleDiscoveredDevice(
              name: name.isNotEmpty ? name : BleConstants.deviceName,
              id: r.device.remoteId.str,
              rssi: r.rssi,
            ));
          }
        }
      }
    } catch (_) {}

    return discovered;
  }

  @override
  Future<void> connect(BleDiscoveredDevice device) async {
    disconnect();

    final bluetoothDevice = _scanCache[device.id];
    if (bluetoothDevice == null) {
      throw Exception('Không tìm thấy thiết bị ${device.name} (${device.id}) trong danh sách quét. Vui lòng thử quét lại.');
    }

    debugPrint('[BLE] Đang kết nối tới ${device.name} (${device.id})...');

    try {
      await bluetoothDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      _connectedBluetoothDevice = bluetoothDevice;
      debugPrint('[BLE] Kết nối Bluetooth thành công! Đang thiết lập MTU...');

      // Yêu cầu MTU lớn hơn để nhận đầy đủ chuỗi JSON thông báo trạng thái
      try {
        await bluetoothDevice.requestMtu(256);
      } catch (e) {
        debugPrint('[BLE] MTU request notice: $e');
      }

      debugPrint('[BLE] Đang tìm kiếm Services...');
      final services = await bluetoothDevice.discoverServices();
      final targetServiceGuid = Guid(BleConstants.serviceUuid);
      final targetCharGuid = Guid(BleConstants.commCharUuid);

      BluetoothCharacteristic? foundChar;
      for (final service in services) {
        if (service.uuid == targetServiceGuid) {
          for (final char in service.characteristics) {
            if (char.uuid == targetCharGuid) {
              foundChar = char;
              break;
            }
          }
        }
      }

      if (foundChar == null) {
        throw Exception('Không tìm thấy Characteristic cấu hình ($targetCharGuid) trên ESP32.');
      }

      _commCharacteristic = foundChar;
      await foundChar.setNotifyValue(true);
      debugPrint('[BLE] Đã đăng ký Notify thành công trên Characteristic: ${foundChar.uuid}');
    } catch (e) {
      disconnect();
      debugPrint('[BLE Connect Error] $e');
      throw Exception('Kết nối Bluetooth tới ESP32 thất bại: $e');
    }
  }

  @override
  Future<void> provisionWifi({
    required String ssid,
    required String password,
    void Function()? onWifiConnected,
    void Function()? onMqttConnected,
  }) async {
    final char = _commCharacteristic;
    if (char == null) {
      throw Exception('Chưa kết nối Bluetooth tới ESP32. Vui lòng quét và kết nối lại.');
    }

    final payload = jsonEncode({
      'action': 'set_wifi',
      'ssid': ssid.trim(),
      'password': password,
    });

    final completer = Completer<void>();
    bool receivedWifiOk = false;
    bool receivedMqttOk = false;

    await _notifySubscription?.cancel();
    _notifySubscription = char.onValueReceived.listen((bytes) {
      if (bytes.isEmpty) return;
      try {
        final text = utf8.decode(bytes).trim();
        debugPrint('[BLE NOTIFY FROM ESP32] $text');
        final Map<String, dynamic> data = jsonDecode(text) as Map<String, dynamic>;
        final status = data['status']?.toString();

        if (status == 'connecting_wifi') {
          debugPrint('[BLE] ESP32 đang kết nối Wi-Fi...');
        } else if (status == 'wifi_connected') {
          receivedWifiOk = true;
          debugPrint('[BLE] ESP32 đã kết nối Wi-Fi thành công! IP: ${data['ip']}');
          onWifiConnected?.call();
        } else if (status == 'mqtt_connected' || status == 'ready') {
          receivedMqttOk = true;
          debugPrint('[BLE] ESP32 đã kết nối MQTT thành công!');
          onMqttConnected?.call();
          if (!completer.isCompleted) {
            completer.complete();
          }
        } else if (status == 'wifi_failed') {
          final errorReason = data['error']?.toString() ?? 'Sai mật khẩu hoặc sóng yếu';
          debugPrint('[BLE] ESP32 báo lỗi Wi-Fi: $errorReason');
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('ESP32 kết nối Wi-Fi thất bại ($errorReason). Vui lòng kiểm tra lại tên Wi-Fi và mật khẩu.'),
            );
          }
        } else if (status == 'mqtt_failed') {
          final errorReason = data['error']?.toString() ?? 'Không tìm thấy broker MQTT';
          debugPrint('[BLE] ESP32 báo lỗi MQTT: $errorReason');
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('ESP32 kết nối MQTT thất bại ($errorReason).'),
            );
          }
        }
      } catch (err) {
        debugPrint('[BLE Parse Error] $err');
      }
    });

    // Gửi cấu hình JSON qua BLE Write
    debugPrint('[BLE TX -> ESP32] Gửi JSON cấu hình: $payload');
    await char.write(utf8.encode(payload), withoutResponse: false);

    // Chờ phản hồi thực tế từ ESP32 trong tối đa 35 giây (ESP32 thử kết nối và timeout 15-20s)
    return completer.future.timeout(
      const Duration(seconds: 35),
      onTimeout: () {
        _notifySubscription?.cancel();
        if (receivedWifiOk && receivedMqttOk) return;
        throw TimeoutException('Quá thời gian chờ ESP32 phản hồi (35s). ESP32 không phản hồi kết quả kết nối Wi-Fi.');
      },
    );
  }

  @override
  void disconnect() {
    _notifySubscription?.cancel();
    _notifySubscription = null;
    try {
      _connectedBluetoothDevice?.disconnect();
    } catch (_) {}
    _connectedBluetoothDevice = null;
    _commCharacteristic = null;
  }
}

/// Dịch vụ BLE giả lập cho Unit Tests
class SimBleProvisioningService implements BleProvisioningService {
  @override
  Future<List<BleDiscoveredDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 1),
  }) async {
    await Future<void>.delayed(timeout);
    return const [
      BleDiscoveredDevice(
        name: BleConstants.deviceName,
        id: '3C:71:BF:42:00:11',
        rssi: -58,
      ),
    ];
  }

  @override
  Future<void> connect(BleDiscoveredDevice device) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> provisionWifi({
    required String ssid,
    required String password,
    void Function()? onWifiConnected,
    void Function()? onMqttConnected,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    onWifiConnected?.call();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    onMqttConnected?.call();
  }

  @override
  void disconnect() {}
}

final bleProvisioningServiceProvider = Provider<BleProvisioningService>((ref) {
  return FlutterBleProvisioningService();
});
