import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/state_views.dart';
import '../data/device_providers.dart';
import '../domain/device.dart';
import 'device_visuals.dart';
import 'widgets/air_conditioner_controls.dart';
import 'widgets/led_rgb_controls.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(devicesControllerProvider.notifier)
          .fetchDeviceHealth(widget.deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesControllerProvider).valueOrNull ?? [];
    final matches = devices.where((item) => item.id == widget.deviceId);
    if (matches.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.auroraCanvasTop,
        body: AmbientBackground(
          child: Center(child: EmptyView(message: context.l10n.emptyTitle)),
        ),
      );
    }
    final device = matches.first;

    if (!_precached) {
      _precached = true;
      final image = DeviceVisuals.detailImage(device);
      if (image != null) precacheImage(AssetImage(image), context);
    }

    return _DeviceDetailScaffold(device: device);
  }
}

/// Scaffold dùng chung cho MỌI loại thiết bị: ảnh sản phẩm full-bleed
/// làm background + glow theo trạng thái + layer control kính nổi.
/// Control chính render theo [DeviceType] — không copy-paste screen.
class _DeviceDetailScaffold extends ConsumerWidget {
  const _DeviceDetailScaffold({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = (device.type == DeviceType.ledRgb && device.rgbColor != null)
        ? device.rgbColor!
        : DeviceVisuals.accent(device.type, Brightness.dark);
    final image = DeviceVisuals.detailImage(device);

    return Scaffold(
      backgroundColor: AppColors.auroraCanvasTop,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: ảnh sản phẩm phóng lớn, canh lệch, Hero từ grid.
          if (image != null)
            Positioned.fill(
              child: Hero(
                tag: 'device-image-${device.id}',
                child: Transform.scale(
                  scale: 1.15,
                  alignment: const Alignment(0.4, -0.3),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.4, -0.3),
                    errorBuilder: (_, __, ___) =>
                        const AmbientBackground(child: SizedBox.expand()),
                  ),
                ),
              ),
            )
          else
            const AmbientBackground(child: SizedBox.expand()),
          // Glow màu toả theo trạng thái thiết bị.
          IgnorePointer(
            child: AnimatedContainer(
              duration: GlassTokens.durationSlow,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.5, -0.4),
                  radius: 1.1,
                  colors: [
                    accent.withValues(
                      alpha: (device.type == DeviceType.lock || device.isOn)
                          ? 0.28
                          : 0.06,
                    ),
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Scrim tối dần về đáy — vùng nội dung.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Theme(
            data: _forcedDarkTheme(context),
            child: SafeArea(
              child: Column(
                children: [
                  GlassAppBar(
                    transparent: true,
                    title: device.name,
                    subtitle: device.subtitle,
                    onBack: () => context.pop(),
                    actions: [
                      GlassIconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: () =>
                            _showDeviceMoreOptions(context, ref, device),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.md,
                        AppSpacing.screen,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Đẩy control xuống nửa dưới, nhường chỗ cho ảnh.
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.16,
                          ),
                          _StatusBlock(
                            device: device,
                            accent: accent,
                            onEditWattage: () =>
                                _showEditWattageDialog(context, ref, device),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _MainControls(device: device, accent: accent),
                          const SizedBox(height: AppSpacing.md),
                          _ManualOverrideCard(device: device),
                          const SizedBox(height: AppSpacing.md),
                          _DeviceHealthCard(device: device),
                          const SizedBox(height: AppSpacing.md),
                          _SecondaryBlock(device: device, accent: accent),
                          const SizedBox(height: AppSpacing.md),
                          _AuditHistorySection(device: device),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ThemeData _forcedDarkTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) return theme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.auroraAccent,
        brightness: Brightness.dark,
        primary: AppColors.auroraAccent,
      ),
      textTheme: theme.textTheme.apply(
        bodyColor: AppColors.onDark,
        displayColor: AppColors.onDark,
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}

void _showDeviceMoreOptions(
  BuildContext context,
  WidgetRef ref,
  Device device,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isOverride = device.isOverrideActive;
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141A29),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.bolt_rounded,
                color: AppColors.auroraAccent,
              ),
              title: const Text(
                'Đổi công suất định mức',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Hiện tại: ${device.energyWatts?.toStringAsFixed(1) ?? 40}W',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditWattageDialog(context, ref, device);
              },
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            ListTile(
              leading: Icon(
                isOverride
                    ? Icons.play_arrow_rounded
                    : Icons.lock_clock_rounded,
                color: isOverride
                    ? AppColors.auroraMint
                    : AppColors.auroraWarning,
              ),
              title: Text(
                isOverride
                    ? 'Khôi phục tự động hóa AI'
                    : 'Khóa ưu tiên thủ công (30 phút)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isOverride
                    ? 'Hủy bỏ đè tay và cho phép AI tiếp tục điều khiển'
                    : 'Giữ nguyên trạng thái thiết bị trong 30 phút tới',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                if (isOverride) {
                  ref
                      .read(devicesControllerProvider.notifier)
                      .resumeAutomation(device.id);
                } else {
                  ref
                      .read(devicesControllerProvider.notifier)
                      .cancelAutomation(device.id, minutes: 30);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showEditWattageDialog(
  BuildContext context,
  WidgetRef ref,
  Device device,
) {
  final controller = TextEditingController(
    text: device.energyWatts != null && device.energyWatts! > 0
        ? device.energyWatts!.toStringAsFixed(0)
        : '40',
  );

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141A29),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.auroraAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.auroraAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cấu Hình Công Suất Định Mức',
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        Text(
                          device.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Công suất danh định (Watts) được HESTA dùng để tính toán năng lượng tiêu thụ, tích phân Riemann kWh và đối soát bậc thang EVN.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Công suất tiêu thụ',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixText: 'W',
                  suffixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.auroraAccent,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.auroraAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [15, 40, 60, 100, 680, 1500, 2200].map((w) {
                  return ActionChip(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    label: Text(
                      '${w}W',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    onPressed: () => controller.text = w.toString(),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.auroraAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final val = double.tryParse(controller.text.trim());
                        if (val == null || val <= 0 || val > 25000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng nhập công suất hợp lệ (1W - 25000W)',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        await ref
                            .read(devicesControllerProvider.notifier)
                            .updateDeviceWattage(device.id, val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.success,
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Đã cập nhật công suất ${device.name}: ${val.toStringAsFixed(0)}W',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Lưu Công Suất',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────
// Khối trạng thái (hàng status pill)
// ─────────────────────────────────────────────────────────────────────
class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.device,
    required this.accent,
    this.onEditWattage,
  });

  final Device device;
  final Color accent;
  final VoidCallback? onEditWattage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pills = <Widget>[];

    if (device.isGate) {
      final gate = device.gateState?.toUpperCase();
      final isClosing = gate == 'CLOSING';
      final isOpening = gate == 'OPENING';
      final isStopped = gate == 'STOPPED' || gate == 'STOP';
      final isClosed =
          gate == 'CLOSED' || gate == 'CLOSE' || (gate == null && device.isOn);
      final isOpen = gate == 'OPEN';
      final targetName = device.apertureLabel;

      final gateLabel = isOpening
          ? 'Đang mở $targetName...'
          : (isClosing
              ? 'Đang đóng $targetName...'
              : (isStopped
                  ? 'Đã tạm dừng'
                  : (isClosed
                      ? 'Đã đóng $targetName'
                      : (isOpen ? 'Đã mở $targetName' : 'Sẵn sàng'))));

      final gateColor = (isOpening || isClosing)
          ? AppColors.auroraWarning
          : (isStopped
                ? Colors.orangeAccent
                : (isClosed ? AppColors.auroraMint : AppColors.orbTeal));

      final gateIcon = (isClosed)
          ? Icons.door_front_door_rounded
          : (isOpen ? Icons.meeting_room_rounded : Icons.sync_rounded);

      pills.addAll([
        GlassStatusPill(icon: gateIcon, label: gateLabel, color: gateColor),
        GlassStatusPill(
          icon: device.status == DeviceStatus.online
              ? Icons.wifi_rounded
              : Icons.wifi_off_rounded,
          label: device.status == DeviceStatus.online
              ? l10n.deviceOnline
              : l10n.deviceOffline,
          color: device.status == DeviceStatus.online
              ? AppColors.auroraMint
              : AppColors.auroraError,
        ),
        if (device.subtitle != null && device.subtitle!.isNotEmpty)
          GlassStatusPill(
            icon: Icons.location_on_outlined,
            label: device.subtitle!,
            color: accent,
          ),
      ]);
    } else if (device.type == DeviceType.lock) {
      pills.addAll([
        GlassStatusPill(icon: Icons.threesixty_rounded, label: '360°'),
        GlassStatusPill(
          icon: device.isOn ? Icons.lock_rounded : Icons.lock_open_rounded,
          label: device.isOn ? l10n.locked : l10n.unlocked,
          color: device.isOn ? AppColors.auroraMint : AppColors.auroraWarning,
        ),
        GlassStatusPill(
          icon: Icons.battery_5_bar_rounded,
          value: '71%',
          label: l10n.battery,
          color: AppColors.auroraMint,
        ),
      ]);
    } else {
      pills.addAll([
        GlassStatusPill(
          label: device.isOn ? l10n.deviceOn : l10n.deviceOff,
          color: device.isOn ? AppColors.auroraMint : AppColors.auroraWarning,
        ),
        GlassStatusPill(
          icon: device.status == DeviceStatus.online
              ? Icons.wifi_rounded
              : Icons.wifi_off_rounded,
          label: device.status == DeviceStatus.online
              ? l10n.deviceOnline
              : l10n.deviceOffline,
          color: device.status == DeviceStatus.online
              ? AppColors.auroraMint
              : AppColors.auroraError,
        ),
        if (device.energyWatts != null && device.energyWatts! > 0)
          GlassStatusPill(
            icon: Icons.bolt_rounded,
            value: '${device.energyWatts!.toStringAsFixed(1)}W',
            label: '${l10n.energy} • Đổi',
            color: accent,
            onTap: onEditWattage,
          ),
        if (device.isOverrideActive)
          GlassStatusPill(
            icon: Icons.lock_clock_rounded,
            value: device.formattedOverrideTime,
            label: 'Khóa tay',
            color: AppColors.auroraWarning,
          ),
        if (device.healthPercent != null)
          GlassStatusPill(
            icon: Icons.health_and_safety_rounded,
            value: '${device.healthPercent!.toStringAsFixed(1)}%',
            label: 'Độ bền',
            color: device.healthPercent! >= 80
                ? AppColors.auroraMint
                : AppColors.auroraWarning,
          ),
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, pill) in pills.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            pill,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Khối điều khiển chính theo DeviceType
// ─────────────────────────────────────────────────────────────────────
class _MainControls extends ConsumerWidget {
  const _MainControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (device.isGate) {
      return _GateControls(device: device, accent: accent);
    }
    return switch (device.type) {
      DeviceType.light => _LightControls(device: device, accent: accent),
      DeviceType.ledRgb => LedRgbControls(device: device, accent: accent),
      DeviceType.lock => _LockControls(device: device),
      DeviceType.thermostat => AirConditionerControls(
        device: device,
        accent: accent,
      ),
      DeviceType.fan => _FanControls(device: device, accent: accent),
      DeviceType.speaker => _SpeakerControls(device: device, accent: accent),
      DeviceType.waterPump => _WaterPumpControls(
        device: device,
        accent: accent,
      ),
      DeviceType.tv => _TvControls(device: device, accent: accent),
      DeviceType.sensor ||
      DeviceType.camera => _SensorControls(device: device, accent: accent),
    };
  }
}

/// Nút nguồn tròn kính dùng chung.
class _PowerButton extends ConsumerWidget {
  const _PowerButton({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      toggled: device.isOn,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ref
              .read(devicesControllerProvider.notifier)
              .updateDevice(device.id, DeviceCommand(isOn: !device.isOn));
        },
        child: GlassContainer(
          shape: BoxShape.circle,
          active: device.isOn,
          fill: device.isOn ? accent : null,
          shadows: device.isOn
              ? GlassTokens.glow(accent, intensity: 0.8)
              : null,
          child: SizedBox.square(
            dimension: 64,
            child: Icon(
              Icons.power_settings_new_rounded,
              color: device.isOn
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _LightControls extends ConsumerStatefulWidget {
  const _LightControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  ConsumerState<_LightControls> createState() => _LightControlsState();
}

class _LightControlsState extends ConsumerState<_LightControls> {
  int _colorTemp = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final device = widget.device;
    final brightness = (device.brightness ?? 0) / 100;

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSegmentedControl(
            segments: [
              GlassSegment(
                label: l10n.colorTempWarm,
                icon: Icons.local_fire_department_outlined,
              ),
              GlassSegment(
                label: l10n.colorTempNeutral,
                icon: Icons.brightness_medium_outlined,
              ),
              GlassSegment(
                label: l10n.colorTempCold,
                icon: Icons.ac_unit_rounded,
              ),
            ],
            selectedIndex: _colorTemp,
            onChanged: (index) => setState(() => _colorTemp = index),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _PowerButton(device: device, accent: widget.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassSlider(
                  value: brightness,
                  label: '${device.brightness ?? 0}%',
                  leadingIcon: Icons.brightness_low_rounded,
                  trailingIcon: Icons.brightness_high_rounded,
                  height: 64,
                  onChanged: (value) {
                    ref
                        .read(devicesControllerProvider.notifier)
                        .updateDevice(
                          device.id,
                          DeviceCommand(
                            brightness: (value * 100).round(),
                            isOn: value > 0,
                          ),
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockControls extends ConsumerWidget {
  const _LockControls({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mint = AppColors.auroraMint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3 thẻ hành động nhanh.
        Row(
          children: [
            Expanded(
              child: GlassIconTile(
                icon: Icons.pin_outlined,
                label: l10n.lockTempCode,
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassIconTile(
                icon: Icons.group_outlined,
                label: l10n.lockMembers,
                color: AppColors.orbViolet,
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassIconTile(
                icon: Icons.auto_awesome_outlined,
                label: l10n.lockScenes,
                color: AppColors.orbTeal,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Kéo để mở khoá — bắt buộc kéo, không tap.
        SlideToConfirm(
          label: device.isOn ? l10n.slideToUnlock : l10n.slideToLock,
          icon: device.isOn ? Icons.lock_open_rounded : Icons.lock_rounded,
          color: device.isOn ? theme.colorScheme.primary : mint,
          onConfirmed: () {
            ref
                .read(devicesControllerProvider.notifier)
                .updateDevice(device.id, DeviceCommand(isOn: !device.isOn));
          },
        ),
      ],
    );
  }
}

class _GateControls extends ConsumerStatefulWidget {
  const _GateControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  ConsumerState<_GateControls> createState() => _GateControlsState();
}

class _GateControlsState extends ConsumerState<_GateControls> {
  static const _transitLockDuration = Duration(milliseconds: 4500);
  bool _transitLocked = false;
  Timer? _transitTimer;

  @override
  void didUpdateWidget(covariant _GateControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextState = widget.device.gateState?.toUpperCase();
    if (nextState != oldWidget.device.gateState?.toUpperCase() &&
        (nextState == 'OPEN' ||
            nextState == 'CLOSED' ||
            nextState == 'STOPPED')) {
      _transitTimer?.cancel();
      _transitTimer = null;
      if (_transitLocked) {
        setState(() => _transitLocked = false);
      }
    }
  }

  @override
  void dispose() {
    _transitTimer?.cancel();
    super.dispose();
  }

  void _armTransitLock() {
    _transitTimer?.cancel();
    setState(() => _transitLocked = true);
    _transitTimer = Timer(_transitLockDuration, () {
      if (mounted) {
        setState(() => _transitLocked = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final theme = Theme.of(context);
    final offline = device.status == DeviceStatus.offline;
    final controller = ref.read(devicesControllerProvider.notifier);

    final gate = device.gateState?.toUpperCase();
    final isClosing = gate == 'CLOSING';
    final isOpening = gate == 'OPENING';
    final isStopped = gate == 'STOPPED' || gate == 'STOP';
    final isClosed =
        gate == 'CLOSED' || gate == 'CLOSE' || (gate == null && device.isOn);
    final isOpen = gate == 'OPEN';
    final isMoving = isOpening || isClosing || _transitLocked;
    final disableOpen = offline || isOpen || isMoving;
    final disableClose = offline || isClosed || isMoving;
    final disableStop = offline || !isMoving;
    final targetName = device.apertureLabel;

    void sendGate(String action) {
      if (action == 'OPEN' && disableOpen) return;
      if (action == 'CLOSE' && disableClose) return;
      if (action == 'STOP' && disableStop) return;
      HapticFeedback.mediumImpact();
      if (action == 'STOP') {
        _transitTimer?.cancel();
        _transitTimer = null;
        setState(() => _transitLocked = false);
      } else {
        _armTransitLock();
      }
      controller.updateDevice(
        device.id,
        DeviceCommand(gateAction: action),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Khối trạng thái & điều khiển 3 nút chính (có khóa liên động hành trình)
        GlassContainer(
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offline
                              ? 'Thiết bị ngoại tuyến'
                              : (isOpening
                                  ? 'Đang mở $targetName...'
                                  : (isClosing
                                      ? 'Đang đóng $targetName...'
                                      : (_transitLocked
                                          ? 'Đang vận hành motor...'
                                          : (isStopped
                                              ? 'Đã dừng $targetName'
                                              : (isClosed
                                                  ? 'Đã đóng $targetName hoàn toàn'
                                                  : (isOpen
                                                      ? 'Đã mở $targetName hoàn toàn'
                                                      : 'Sẵn sàng điều khiển')))))),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: offline
                                ? AppColors.auroraError
                                : (isMoving
                                    ? AppColors.auroraWarning
                                    : (isClosed
                                        ? AppColors.auroraMint
                                        : AppColors.orbTeal)),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isClosed
                              ? AppColors.auroraMint
                              : AppColors.orbTeal)
                          .withValues(alpha: 0.15),
                      boxShadow: GlassTokens.glow(
                        isClosed ? AppColors.auroraMint : AppColors.orbTeal,
                        intensity: 0.35,
                      ),
                    ),
                    child: Icon(
                      isClosed
                          ? Icons.door_front_door_rounded
                          : Icons.meeting_room_rounded,
                      color: isClosed
                          ? AppColors.auroraMint
                          : AppColors.orbTeal,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // 3 Nút lệnh: Mở (OPEN), Dừng (STOP), Đóng (CLOSE)
              Row(
                children: [
                  Expanded(
                    child: _GateActionButton(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Mở',
                      active: isOpening || isOpen,
                      accent: AppColors.orbTeal,
                      enabled: !disableOpen,
                      onTap: () => sendGate('OPEN'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GateActionButton(
                      icon: Icons.stop_rounded,
                      label: 'Dừng',
                      active: isStopped,
                      accent: Colors.orangeAccent,
                      enabled: !disableStop,
                      onTap: () => sendGate('STOP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GateActionButton(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Đóng',
                      active: isClosing || isClosed,
                      accent: AppColors.auroraMint,
                      enabled: !disableClose,
                      onTap: () => sendGate('CLOSE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!offline && (isMoving || isClosed || isOpen)) ...[
          const SizedBox(height: AppSpacing.md),
          // Thanh trượt xác nhận thao tác mở / đóng / dừng an toàn
          SlideToConfirm(
            label: isMoving
                ? 'Kéo để DỪNG $targetName'
                : (isClosed
                    ? 'Kéo để MỞ $targetName'
                    : 'Kéo để ĐÓNG $targetName'),
            icon: isMoving
                ? Icons.stop_circle_outlined
                : (isClosed ? Icons.lock_open_rounded : Icons.lock_rounded),
            color: isMoving
                ? Colors.orangeAccent
                : (isClosed ? AppColors.orbTeal : AppColors.auroraMint),
            onConfirmed: () {
              if (isMoving) {
                sendGate('STOP');
              } else if (isClosed) {
                sendGate('OPEN');
              } else if (isOpen) {
                sendGate('CLOSE');
              }
            },
          ),
        ],
      ],
    );
  }
}

class _GateActionButton extends StatelessWidget {
  const _GateActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: GlassTokens.durationMed,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.12),
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: active
                ? GlassTokens.glow(accent, intensity: 0.35)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: enabled
                    ? (active ? accent : Colors.white.withValues(alpha: 0.85))
                    : Colors.white.withValues(alpha: 0.3),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: enabled
                      ? (active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75))
                      : Colors.white.withValues(alpha: 0.3),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FanControls extends ConsumerWidget {
  const _FanControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  /// Mức hiện tại 0..3 từ currentState.fan (OFF/LOW/MED/HIGH).
  int get _speed {
    if (!device.isOn) return 0;
    return switch ((device.acFan ?? '').toUpperCase()) {
      'LOW' || '1' => 1,
      'MED' || 'MEDIUM' || '2' => 2,
      'HIGH' || '3' => 3,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offline = device.status == DeviceStatus.offline;
    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSegmentedControl(
            segments: [
              GlassSegment(label: l10n.deviceOff),
              GlassSegment(label: l10n.fanLow),
              GlassSegment(label: l10n.fanMedium),
              GlassSegment(label: l10n.fanHigh),
            ],
            selectedIndex: _speed,
            onChanged: (index) {
              if (offline) return;
              HapticFeedback.selectionClick();
              ref
                  .read(devicesControllerProvider.notifier)
                  .updateDevice(
                    device.id,
                    DeviceCommand(
                      customAction: 'SET_SPEED',
                      customParams: {'speed': index},
                    ),
                  );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: _PowerButton(device: device, accent: accent),
          ),
        ],
      ),
    );
  }
}

/// Remote TV theo iot-tv.http: nguồn, âm lượng, kênh, D-pad, phím hệ thống.
class _TvControls extends ConsumerWidget {
  const _TvControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = device.status == DeviceStatus.offline;

    void press(String action) {
      if (offline) return;
      HapticFeedback.lightImpact();
      ref
          .read(devicesControllerProvider.notifier)
          .updateDevice(device.id, DeviceCommand(customAction: action));
    }

    Widget key(IconData icon, String label, String action) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs / 2),
        child: _GateActionButton(
          icon: icon,
          label: label,
          active: false,
          accent: accent,
          enabled: !offline,
          onTap: () => press(action),
        ),
      ),
    );

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _PowerButton(device: device, accent: accent),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              key(Icons.volume_down_rounded, 'Âm lượng -', 'VOL_DOWN'),
              key(Icons.volume_off_rounded, 'Tắt tiếng', 'MUTE'),
              key(Icons.volume_up_rounded, 'Âm lượng +', 'VOL_UP'),
            ],
          ),
          Row(
            children: [
              key(Icons.keyboard_arrow_down_rounded, 'Kênh -', 'CH_DOWN'),
              key(Icons.input_rounded, 'Nguồn vào', 'INPUT'),
              key(Icons.keyboard_arrow_up_rounded, 'Kênh +', 'CH_UP'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Spacer(),
              key(Icons.arrow_drop_up_rounded, 'Lên', 'UP'),
              const Spacer(),
            ],
          ),
          Row(
            children: [
              key(Icons.arrow_left_rounded, 'Trái', 'LEFT'),
              key(Icons.radio_button_checked_rounded, 'OK', 'OK'),
              key(Icons.arrow_right_rounded, 'Phải', 'RIGHT'),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              key(Icons.arrow_drop_down_rounded, 'Xuống', 'DOWN'),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              key(Icons.arrow_back_rounded, 'Quay lại', 'BACK'),
              key(Icons.home_rounded, 'Home', 'HOME'),
              key(Icons.menu_rounded, 'Menu', 'MENU'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeakerControls extends ConsumerWidget {
  const _SpeakerControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final volume = (device.brightness ?? 40) / 100;

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PowerButton(device: device, accent: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassSlider(
                  value: volume,
                  height: 64,
                  label: '${l10n.volume} ${(volume * 100).round()}%',
                  leadingIcon: Icons.volume_down_rounded,
                  trailingIcon: Icons.volume_up_rounded,
                  onChanged: (value) {
                    ref
                        .read(devicesControllerProvider.notifier)
                        .updateDevice(
                          device.id,
                          DeviceCommand(brightness: (value * 100).round()),
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterPumpControls extends ConsumerWidget {
  const _WaterPumpControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final offline = device.status == DeviceStatus.offline;

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offline
                          ? l10n.deviceOffline
                          : (device.isOn ? l10n.deviceOn : l10n.deviceOff),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: device.isOn
                            ? AppColors.auroraMint
                            : Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _PowerButton(device: device, accent: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  color: device.isOn
                      ? accent
                      : Colors.white.withValues(alpha: 0.4),
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    device.isOn
                        ? (device.subtitle ?? 'Máy bơm đang hoạt động')
                        : 'Máy bơm đang tắt',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                GlassToggle(
                  value: device.isOn,
                  onChanged: offline
                      ? null
                      : (val) {
                          ref
                              .read(devicesControllerProvider.notifier)
                              .updateDevice(
                                device.id,
                                DeviceCommand(isOn: val),
                              );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorControls extends StatelessWidget {
  const _SensorControls({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
              boxShadow: GlassTokens.glow(accent, intensity: 0.4),
            ),
            child: Icon(
              DeviceVisuals.icon(device.type),
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  device.subtitle ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Khối phụ: lịch trình theo thứ (light) / lịch sử mở khoá (lock)…
// ─────────────────────────────────────────────────────────────────────
class _SecondaryBlock extends StatelessWidget {
  const _SecondaryBlock({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (device.isGate) {
      return const _GateInfoCard();
    }
    return switch (device.type) {
      DeviceType.light || DeviceType.ledRgb => _WeeklySchedule(accent: accent),
      DeviceType.lock => const _LockHistory(),
      _ => _EnergyHistory(accent: accent),
    };
  }
}

class _GateInfoCard extends StatelessWidget {
  const _GateInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.auroraMint,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Hướng dẫn điều khiển cổng',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• Mở cổng: Kích hoạt động cơ trượt mở cổng cho đến khi chạm công tắc giới hạn.\n'
            '• Đóng cổng: Kích hoạt động cơ trượt đóng cổng an toàn.\n'
            '• Dừng: Dừng ngay chuyển động của cổng tại vị trí hiện tại.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySchedule extends StatefulWidget {
  const _WeeklySchedule({required this.accent});

  final Color accent;

  @override
  State<_WeeklySchedule> createState() => _WeeklyScheduleState();
}

class _WeeklyScheduleState extends State<_WeeklySchedule> {
  final _enabled = List<bool>.generate(7, (i) => i.isEven);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // Thứ trong tuần theo locale, bắt đầu từ Chủ nhật như ảnh tham chiếu.
    final firstSunday = DateTime(2026, 1, 4);
    final dayFormat = DateFormat.E(l10n.localeName);

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.schedule.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < 7; i++) ...[
            if (i > 0)
              Divider(
                height: AppSpacing.md,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    dayFormat.format(firstSunday.add(Duration(days: i))),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scheduleOnTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      Text(
                        i.isEven ? '07:00' : '08:00',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scheduleOffTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      Text('22:00', style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
                GlassToggle(
                  value: _enabled[i],
                  size: 0.85,
                  onChanged: (value) => setState(() => _enabled[i] = value),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LockHistory extends StatelessWidget {
  const _LockHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final entries = [
      ('21:21', l10n.lockHistoryFingerprint, Icons.fingerprint_rounded),
      ('18:04', l10n.lockHistoryKeypad, Icons.pin_outlined),
      ('08:30', l10n.lockHistoryApp, Icons.smartphone_rounded),
    ];

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.lockHistory.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              Text(
                l10n.viewAll,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (index, entry) in entries.indexed) ...[
            if (index > 0)
              Divider(
                height: AppSpacing.md,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            Row(
              children: [
                Icon(
                  entry.$3,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(entry.$2, style: theme.textTheme.labelMedium),
                ),
                Text(
                  entry.$1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EnergyHistory extends StatelessWidget {
  const _EnergyHistory({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    const values = [.35, .45, .55, .70, .65, .80, .75, .50, .55, .90, .70, .40];

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.usageHistory.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FractionallySizedBox(
                        heightFactor: value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: value),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PHO-043: Manual Override Card (Khóa ưu tiên điều khiển tay 30 phút)
// ─────────────────────────────────────────────────────────────────────
class _ManualOverrideCard extends ConsumerStatefulWidget {
  const _ManualOverrideCard({required this.device});

  final Device device;

  @override
  ConsumerState<_ManualOverrideCard> createState() =>
      _ManualOverrideCardState();
}

class _ManualOverrideCardState extends ConsumerState<_ManualOverrideCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = widget.device;
    final isOverride = device.isOverrideActive;

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.auroraWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.lock_clock_rounded,
                        color: AppColors.auroraWarning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Khóa Ưu Tiên Thủ Công',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (isOverride
                              ? AppColors.auroraWarning
                              : AppColors.auroraMint)
                          .withValues(alpha: 0.15),
                  border: Border.all(
                    color:
                        (isOverride
                                ? AppColors.auroraWarning
                                : AppColors.auroraMint)
                            .withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isOverride
                      ? '🔒 ${device.formattedOverrideTime}'
                      : '🟢 Tự động AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isOverride
                        ? AppColors.auroraWarning
                        : AppColors.auroraMint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isOverride
                ? 'Thiết bị đang được ưu tiên điều khiển tay. Mọi kịch bản tự động hóa AI sẽ bị khóa đến khi hết đếm lùi.'
                : 'Bật chế độ khóa thủ công để giữ nguyên trạng thái hiện tại và ngăn kịch bản AI tự ý thay đổi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (isOverride) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.auroraMint,
                      side: BorderSide(
                        color: AppColors.auroraMint.withValues(alpha: 0.6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(devicesControllerProvider.notifier)
                          .resumeAutomation(device.id);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Khôi phục AI'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.auroraWarning,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(devicesControllerProvider.notifier)
                          .cancelAutomation(device.id, minutes: 30);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('+30 Phút'),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.auroraWarning,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(devicesControllerProvider.notifier)
                          .cancelAutomation(device.id, minutes: 30);
                    },
                    icon: const Icon(Icons.lock_rounded, size: 16),
                    label: const Text('Khóa Tự Động 30 Phút'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PHO-034 & PHO-042: Device Hardware Health & Relay Lifespan Card
// ─────────────────────────────────────────────────────────────────────
class _DeviceHealthCard extends StatelessWidget {
  const _DeviceHealthCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthPercent = device.healthPercent ?? 98.5;
    final switchCycles = device.switchCycles ?? 1450;
    final maxRatedCycles = device.maxRatedCycles ?? 100000;
    final uptimePercent = device.uptimePercent ?? 99.4;
    final isChattering = device.chatteringWarning == true;
    final isTripped = device.safetyTripped == true;

    final healthColor = isChattering || isTripped
        ? AppColors.auroraError
        : (healthPercent >= 80
              ? AppColors.auroraMint
              : AppColors.auroraWarning);

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: healthColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sức Khỏe & Độ Bền Relay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.15),
                  border: Border.all(color: healthColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isChattering
                      ? '⚠️ Dội Xung'
                      : '${healthPercent.toStringAsFixed(1)}% còn lại',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: healthColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Lifespan progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuổi thọ cơ học relay:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              Text(
                '${switchCycles.toString()} / $maxRatedCycles chu kỳ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (healthPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Uptime indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Độ sẵn sàng (Uptime 7 ngày):',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              Text(
                '🟢 ${uptimePercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.auroraMint,
                ),
              ),
            ],
          ),

          if (isChattering || isTripped) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.auroraError.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.auroraError.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.auroraError,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cảnh báo: Phát hiện tiếp điểm đổi trạng thái >10 lần/phút! Mạch đã ngắt an toàn chống dội xung chattering.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.auroraError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Khối Nhật Ký & Báo Cáo Kiểm Toán Excel (PHO-035)
// ─────────────────────────────────────────────────────────────────────
class _AuditHistorySection extends ConsumerStatefulWidget {
  const _AuditHistorySection({required this.device});
  final Device device;

  @override
  ConsumerState<_AuditHistorySection> createState() =>
      _AuditHistorySectionState();
}

class _AuditHistorySectionState extends ConsumerState<_AuditHistorySection> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<Map<String, dynamic>> _history = [];

  static const Color _emerald = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ref
          .read(devicesControllerProvider.notifier)
          .getAuditHistory(widget.device.id);
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() => _isExporting = true);
    try {
      final path = await ref
          .read(devicesControllerProvider.notifier)
          .exportAuditExcel(widget.device.id, widget.device.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Đã xuất báo cáo Excel (.xlsx) thành công:\n$path',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.auroraError,
          content: Text('Lỗi khi xuất báo cáo Excel: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nhật Ký & Báo Cáo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Nút Xuất Excel
              InkWell(
                onTap: _isExporting ? null : _handleExportExcel,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.15),
                    border: Border.all(color: _emerald.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isExporting)
                        const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _emerald,
                          ),
                        )
                      else
                        const Icon(
                          Icons.table_chart_rounded,
                          size: 14,
                          color: _emerald,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _isExporting ? 'Đang xuất...' : 'Xuất Excel',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Timeline Body
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'Chưa có lịch sử hoạt động',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = _history[index];
                final source = item['source']?.toString() ?? 'APP';
                final changedAtStr = item['changedAt']?.toString();
                final dt = changedAtStr != null
                    ? DateTime.tryParse(changedAtStr)
                    : null;
                final timeLabel = dt != null
                    ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}'
                    : 'Gần đây';

                final (sourceLabel, sourceColor, sourceIcon) = switch (source) {
                  'APP' => (
                    'Bấm App',
                    Colors.blueAccent,
                    Icons.touch_app_rounded,
                  ),
                  'MANUAL_OVERRIDE' => (
                    'Khóa tay 30p',
                    Colors.amberAccent,
                    Icons.lock_clock_rounded,
                  ),
                  'AUTOMATION' => (
                    'Tự động hóa AI',
                    Colors.purpleAccent,
                    Icons.smart_toy_rounded,
                  ),
                  'VOICE' => (
                    'Giọng nói',
                    Colors.orangeAccent,
                    Icons.mic_rounded,
                  ),
                  _ => ('Vật lý', Colors.blueGrey, Icons.power_rounded),
                };

                final prevMap = item['previousState'] as Map?;
                final newMap = item['newState'] as Map?;
                final prevStr = _formatAuditState(prevMap);
                final newStr = _formatAuditState(newMap);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sourceColor,
                        boxShadow: [
                          BoxShadow(
                            color: sourceColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: sourceColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sourceIcon,
                                      size: 10,
                                      color: sourceColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      sourceLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: sourceColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  prevStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: Colors.white38,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  newStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatAuditState(Map? state) {
    if (state == null) return 'N/A';
    if (state.containsKey('manualOverride')) {
      return state['manualOverride'] == true
          ? 'Đè tay ${state['durationMinutes'] ?? 30}p'
          : 'Hủy đè';
    }
    if (state.containsKey('isOn')) {
      final on = state['isOn'] == true;
      if (!on) return 'TẮT';
      final b = state['brightness'];
      return b != null ? 'BẬT ($b%)' : 'BẬT';
    }
    return state.values.firstOrNull?.toString() ?? 'OK';
  }
}
