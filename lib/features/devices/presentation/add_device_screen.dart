import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../home/data/home_providers.dart';
import '../../rooms/data/room_providers.dart';
import '../data/device_providers.dart';
import '../domain/device_onboarding_models.dart';
import 'onboarding_controller.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final TextEditingController _qrInputController = TextEditingController();
  final TextEditingController _ssidController =
      TextEditingController(text: 'SYNA_Home_5G');
  final TextEditingController _wifiPasswordController =
      TextEditingController(text: 'syna@2026');
  final TextEditingController _deviceNameController = TextEditingController();
  late final MobileScannerController _scannerController;

  bool _obscureWifiPassword = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _qrInputController.dispose();
    _ssidController.dispose();
    _wifiPasswordController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background soft ambient glow
          Positioned(
            top: -100,
            right: -50,
            width: 300,
            height: 300,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? AppColors.auroraMint : AppColors.primary)
                      .withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Glass App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Quay lại',
                        onTap: () {
                          if (state.step == OnboardingStep.completed) {
                            ref.read(devicesControllerProvider.notifier).refresh();
                            context.go('/home');
                          } else {
                            context.pop();
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Thêm Thiết Bị Mới',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step Progress Indicator
                _buildProgressHeader(state.step),

                // Main Step Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.sm,
                      AppSpacing.screen,
                      AppSpacing.lg,
                    ),
                    child: _buildStepContent(state, notifier),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(OnboardingStep step) {
    int currentStep = 1;
    String stepLabel = '1/5 Quét mã QR';

    switch (step) {
      case OnboardingStep.scanQr:
        currentStep = 1;
        stepLabel = 'Bước 1/5: Quét mã QR';
      case OnboardingStep.verifyDevice:
        currentStep = 2;
        stepLabel = 'Bước 2/5: Xác nhận thiết bị';
      case OnboardingStep.bleScanning:
      case OnboardingStep.bleConnected:
        currentStep = 3;
        stepLabel = 'Bước 3/5: Kết nối Bluetooth';
      case OnboardingStep.wifiProvisioning:
      case OnboardingStep.mqttConnecting:
        currentStep = 4;
        stepLabel = 'Bước 4/5: Cấu hình Wi-Fi & MQTT';
      case OnboardingStep.homeRoomSelection:
      case OnboardingStep.claiming:
        currentStep = 5;
        stepLabel = 'Bước 5/5: Gán phòng & Hoàn tất';
      case OnboardingStep.completed:
        currentStep = 5;
        stepLabel = 'Hoàn tất thành công!';
      case OnboardingStep.error:
        stepLabel = 'Đã có lỗi xảy ra';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (step != OnboardingStep.error && step != OnboardingStep.completed)
                Text(
                  '$currentStep / 5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep / 5.0,
              minHeight: 4,
              backgroundColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    if (state.errorMessage != null && state.step == OnboardingStep.error) {
      return _buildErrorCard(state, notifier);
    }

    switch (state.step) {
      case OnboardingStep.scanQr:
        return _buildScanQrStep(state, notifier);
      case OnboardingStep.verifyDevice:
        return _buildVerifyDeviceStep(state, notifier);
      case OnboardingStep.bleScanning:
      case OnboardingStep.bleConnected:
        return _buildBleStep(state, notifier);
      case OnboardingStep.wifiProvisioning:
      case OnboardingStep.mqttConnecting:
        return _buildWifiStep(state, notifier);
      case OnboardingStep.homeRoomSelection:
      case OnboardingStep.claiming:
        return _buildHomeRoomStep(state, notifier);
      case OnboardingStep.completed:
        return _buildCompletedStep(state);
      case OnboardingStep.error:
        return _buildErrorCard(state, notifier);
    }
  }

  // =========================================================================
  // STEP 1: SCAN QR
  // =========================================================================
  Widget _buildScanQrStep(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // Scanner Viewport
        GlassContainer(
          radius: AppRadius.xl,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Container(
                height: 270,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Live Camera Stream
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (BarcodeCapture capture) {
                          for (final barcode in capture.barcodes) {
                            final raw = barcode.rawValue;
                            if (raw != null && raw.trim().isNotEmpty) {
                              notifier.onQrScanned(raw.trim());
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error) {
                          return Container(
                            color: Colors.black87,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_rounded,
                                  color: Colors.white54,
                                  size: 40,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Không thể khởi động Camera: ${error.errorCode.name}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                const Text(
                                  'Vui lòng cấp quyền Camera hoặc nhập Onboarding Token bên dưới.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Holographic corner targeting reticles
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: primary, width: 3),
                              left: BorderSide(color: primary, width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: primary, width: 3),
                              right: BorderSide(color: primary, width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: primary, width: 3),
                              left: BorderSide(color: primary, width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: primary, width: 3),
                              right: BorderSide(color: primary, width: 3),
                            ),
                          ),
                        ),
                      ),

                      // Camera tools (Switch camera / Torch)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 18),
                              tooltip: 'Đổi camera trước/sau',
                              onPressed: () => _scannerController.switchCamera(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                              tooltip: 'Bật/Tắt đèn Flash',
                              onPressed: () => _scannerController.toggleTorch(),
                            ),
                          ],
                        ),
                      ),

                      // Guidance label
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Hướng camera vào mã QR của thiết bị',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Quét mã QR được in trên thiết bị hoặc tem dán',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Fallback: Manual QR Code / Token Input
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoặc nhập mã Token / Payload QR:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _qrInputController,
                decoration: InputDecoration(
                  hintText: 'syna://device/register?token=...',
                  prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => _qrInputController.clear(),
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          final text = _qrInputController.text.trim();
                          if (text.isNotEmpty) {
                            notifier.onQrScanned(text);
                          }
                        },
                  icon: state.isLoading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(state.isLoading ? 'Đang kiểm tra...' : 'Xác thực mã QR'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 2: VERIFY DEVICE
  // =========================================================================
  Widget _buildVerifyDeviceStep(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    final preview = state.preview;
    final theme = Theme.of(context);

    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.devices_other_rounded,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tìm thấy thiết bị!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                preview.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Specs pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Loại: ${preview.deviceType} • Model: ${preview.model ?? "N/A"}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),

              if (preview.serialNumber != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Serial: ${preview.serialNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Bạn có muốn bắt đầu ghép nối Bluetooth và cấu hình Wi-Fi cho thiết bị này?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => notifier.reset(),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () => notifier.confirmDevice(),
                      child: state.isLoading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Tiếp tục'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 3: BLE SCANNING & CONNECT
  // =========================================================================
  Widget _buildBleStep(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    final theme = Theme.of(context);
    final targetDevice = state.selectedBleDevice;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Bluetooth radar icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Đang tìm kiếm thiết bị SYNA...',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Đảm bảo bo mạch ESP32-S3 đã cấp nguồn và ở gần điện thoại',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (targetDevice != null) ...[
                GlassContainer(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.auroraMint.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          color: AppColors.auroraMint,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetDevice.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'MAC: ${targetDevice.id} • Tín hiệu: Tốt (${targetDevice.rssi} dBm)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => notifier.connectBleDevice(targetDevice),
                    icon: state.isLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.bluetooth_connected_rounded),
                    label: Text(state.isLoading ? 'Đang kết nối...' : 'Kết nối BLE'),
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
                if (state.isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Đang quét Bluetooth tìm thiết bị SYNA...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ] else ...[
                  Text(
                    state.errorMessage ?? 'Không tìm thấy thiết bị ESP32 (SYNA-ESP32S3).',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.auroraWarning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => notifier.confirmDevice(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử quét lại'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 4: WI-FI PROVISIONING & MQTT DISCOVERY
  // =========================================================================
  Widget _buildWifiStep(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cấu hình Wi-Fi cho ESP32',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ESP32 sẽ kết nối và phản hồi xác nhận qua BLE',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              TextField(
                controller: _ssidController,
                decoration: InputDecoration(
                  labelText: 'Tên mạng Wi-Fi (SSID)',
                  prefixIcon: const Icon(Icons.wifi_outlined, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: _wifiPasswordController,
                obscureText: _obscureWifiPassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu Wi-Fi',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureWifiPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureWifiPassword = !_obscureWifiPassword;
                      });
                    },
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Live checklist status
              if (state.isLoading || state.step == OnboardingStep.mqttConnecting || state.wifiConnected) ...[
                _buildStatusRow(
                  title: 'Đang truyền thông tin qua BLE tới ESP32',
                  isDone: true,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  title: 'ESP32 kết nối Wi-Fi thành công',
                  isDone: state.wifiConnected,
                  isLoading: state.isLoading && !state.wifiConnected,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  title: 'mDNS tìm thấy Broker & Kết nối MQTT',
                  isDone: state.mqttConnected,
                  isLoading: state.isLoading && state.wifiConnected && !state.mqttConnected,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          notifier.submitWifiCredentials(
                            _ssidController.text,
                            _wifiPasswordController.text,
                          );
                        },
                  icon: state.isLoading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    state.isLoading ? 'Đang gửi qua BLE...' : 'Truyền thông tin Wi-Fi',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required String title,
    required bool isDone,
    bool isLoading = false,
  }) {
    return Row(
      children: [
        if (isLoading)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isDone ? AppColors.auroraMint : Colors.grey,
          ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDone ? null : (isLoading ? Theme.of(context).colorScheme.primary : Colors.grey),
            fontWeight: (isDone || isLoading) ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 5: HOME, ROOM & NAME SELECTION
  // =========================================================================
  Widget _buildHomeRoomStep(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    final theme = Theme.of(context);
    final homesAsync = ref.watch(myHomesProvider);
    final rooms = ref.watch(roomsProvider);

    final homes = homesAsync.valueOrNull ?? [];
    if (state.selectedHomeId == null && homes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateSelectedHomeAndRoom(homeId: homes.first.id);
      });
    }

    if (state.selectedRoomId == null && rooms.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateSelectedHomeAndRoom(roomId: rooms.first.id);
      });
    }

    if (_deviceNameController.text.isEmpty && state.customDeviceName != null) {
      _deviceNameController.text = state.customDeviceName!;
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoàn tất cấu hình thiết bị',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn vị trí ngôi nhà và phòng đặt thiết bị trong gia đình',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Device custom name
              Text(
                'Tên thiết bị:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _deviceNameController,
                onChanged: (val) => notifier.updateSelectedHomeAndRoom(customName: val),
                decoration: InputDecoration(
                  hintText: 'VD: Đèn phòng khách',
                  prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Select Home
              Text(
                'Ngôi nhà:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: state.selectedHomeId ?? (homes.isNotEmpty ? homes.first.id : null),
                    hint: const Text('Chọn nhà'),
                    items: homes.map((h) {
                      return DropdownMenuItem<String>(
                        value: h.id,
                        child: Text(h.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateSelectedHomeAndRoom(homeId: val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Select Room
              Text(
                'Phòng:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: state.selectedRoomId ?? (rooms.isNotEmpty ? rooms.first.id : null),
                    hint: const Text('Chọn phòng'),
                    items: rooms.map((r) {
                      return DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(r.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateSelectedHomeAndRoom(roomId: val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => notifier.claimDevice(),
                  icon: state.isLoading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(state.isLoading ? 'Đang lưu thiết bị...' : 'Hoàn tất ghép nối'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 6: COMPLETED SUCCESS SCREEN
  // =========================================================================
  Widget _buildCompletedStep(OnboardingState state) {
    final theme = Theme.of(context);
    final rooms = ref.watch(roomsProvider);
    final roomName = rooms
        .cast<dynamic>()
        .firstWhere(
          (r) => r.id == state.selectedRoomId,
          orElse: () => null,
        )
        ?.name ?? 'Phòng khách';

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.auroraMint.withValues(alpha: 0.15),
                  boxShadow: GlassTokens.glow(AppColors.auroraMint, intensity: 0.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.auroraMint,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Thêm Thiết Bị Thành Công!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.customDeviceName ?? 'SYNA Smart Device',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phòng:'),
                        Text(
                          roomName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trạng thái:'),
                        Row(
                          children: [
                            Icon(Icons.circle, color: AppColors.auroraMint, size: 10),
                            SizedBox(width: 6),
                            Text(
                              'Trực tuyến (Online)',
                              style: TextStyle(
                                color: AppColors.auroraMint,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(devicesControllerProvider.notifier).refresh();
                    context.go('/home');
                  },
                  child: const Text('Xong'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
    OnboardingState state,
    OnboardingController notifier,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.auroraWarning.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.auroraWarning,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Lỗi ghép nối',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.errorMessage ?? 'Đã xảy ra lỗi không xác định trong quá trình onboarding.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => notifier.retry(),
                      child: const Text('Thử lại'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
