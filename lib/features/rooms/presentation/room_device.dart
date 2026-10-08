import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syna/l10n/app_localizations.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../devices/presentation/device_visuals.dart';
import '../data/room_providers.dart';

/// Nhóm filter map theo [DeviceType].
enum _DeviceFilter { all, lighting, electric, sensors, other }

extension _DeviceFilterX on _DeviceFilter {
  bool matches(DeviceType type) => switch (this) {
    _DeviceFilter.all => true,
    _DeviceFilter.lighting =>
      type == DeviceType.light || type == DeviceType.ledRgb,
    _DeviceFilter.electric =>
      type == DeviceType.thermostat ||
          type == DeviceType.fan ||
          type == DeviceType.speaker,
    _DeviceFilter.sensors =>
      type == DeviceType.sensor || type == DeviceType.camera,
    _DeviceFilter.other => type == DeviceType.lock,
  };
}


class RoomDeviceScreen extends ConsumerStatefulWidget {
  const RoomDeviceScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<RoomDeviceScreen> createState() => _RoomDeviceScreenState();
}

class _RoomDeviceScreenState extends ConsumerState<RoomDeviceScreen> {
  _DeviceFilter _filter = _DeviceFilter.all;
  final _scrollController = ScrollController();
  double _parallax = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _parallax = _scrollController.offset * 0.25);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      final rooms = ref.read(roomsProvider);
      final matched = rooms.where((r) => r.id == widget.roomId).firstOrNull;
      final key = matched?.name ?? matched?.slug ?? widget.roomId;
      final background = DeviceVisuals.roomBackground(key);
      if (background != null) {
        precacheImage(AssetImage(background), context);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _filterLabel(_DeviceFilter filter) {
    final l10n = context.l10n;
    return switch (filter) {
      _DeviceFilter.all => l10n.filterAll,
      _DeviceFilter.lighting => l10n.filterLighting,
      _DeviceFilter.electric => l10n.filterElectric,
      _DeviceFilter.sensors => l10n.filterSensors,
      _DeviceFilter.other => l10n.filterOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final devicesAsync = ref.watch(devicesControllerProvider);
    final rooms = ref.watch(roomsProvider);
    final matchedRooms = rooms.where((r) => r.id == widget.roomId).toList();
    final roomName = matchedRooms.isEmpty
        ? widget.roomId
        : matchedRooms.first.name;
    // Ảnh nền tra theo tên / slug phòng (id backend là UUID).
    final background = DeviceVisuals.roomBackground(
      matchedRooms.isEmpty
          ? widget.roomId
          : (matchedRooms.first.name.isNotEmpty
              ? matchedRooms.first.name
              : matchedRooms.first.slug),
    );

    final allDevices = devicesAsync.valueOrNull ?? const <Device>[];
    final roomDevices = allDevices
        .where((d) => d.roomId == widget.roomId)
        .toList();
    final filtered = roomDevices.where((d) => _filter.matches(d.type)).toList();
    final activeCount = roomDevices.where((d) => d.isOn).length;

    return Scaffold(
      backgroundColor: AppColors.auroraCanvasTop,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh nền phòng full-bleed + parallax nhẹ khi scroll.
          if (background != null)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, -_parallax),
                child: Image.asset(
                  background,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          // Scrim tối dần để chữ trắng đạt contrast ≥ 4.5:1.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          // Ép dark theme cho nội dung đặt trên ảnh tối.
          Theme(
            data: Theme.of(context).brightness == Brightness.dark
                ? theme
                : ThemeData(
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
                  ),
            child: SafeArea(
              child: Column(
                children: [
                  GlassAppBar(
                    transparent: true,
                    onBack: () => context.pop(),
                    actions: [
                      GlassIconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            roomName,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.roomDevicesSummary(
                            roomDevices.length,
                            activeCount,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: _DeviceFilter.values.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final filter = _DeviceFilter.values[index];
                        return GlassFilterChip(
                          label: _filterLabel(filter),
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: devicesAsync.isLoading && roomDevices.isEmpty
                        ? const LoadingView()
                        : filtered.isEmpty
                        ? EmptyView(
                            message: l10n.emptyTitle,
                            icon: Icons.devices_other_rounded,
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth > 700 ? 4 : 2;
                              return GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.screen,
                                  AppSpacing.md,
                                  AppSpacing.screen,
                                  AppSpacing.navClearance,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: AppSpacing.md,
                                      crossAxisSpacing: AppSpacing.md,
                                      childAspectRatio: 3 / 4,
                                    ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final device = filtered[index];
                                  return _RoomDeviceCard(
                                    device: device,
                                    onOpen: () => context.push(
                                      '/rooms/${widget.roomId}'
                                      '/devices/${device.id}',
                                    ),
                                  );
                                },
                              );
                            },
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
}

/// Card kính của một thiết bị trong phòng: ảnh sản phẩm phía trên,
/// tên + loại, control ở đáy đổi theo [DeviceType].
class _RoomDeviceCard extends ConsumerWidget {
  const _RoomDeviceCard({required this.device, required this.onOpen});

  final Device device;
  final VoidCallback onOpen;

  // Ma trận desaturate cho ảnh khi thiết bị OFF.
  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = DeviceVisuals.accent(device.type, Brightness.dark);
    final image = DeviceVisuals.productImage(device);
    final isOn = device.isOn;

    return GlassCard(
      onTap: onOpen,
      active: isOn,
      radius: AppRadius.hero - 4,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderGradient: isOn
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.6),
                accent.withValues(alpha: 0.08),
              ],
            )
          : null,
      shadows: isOn ? GlassTokens.glow(accent, intensity: 0.3) : null,
      semanticLabel: device.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: device.status == DeviceStatus.offline
                    ? Colors.white.withValues(alpha: 0.3)
                    : (isOn
                          ? AppColors.auroraMint
                          : Colors.white.withValues(alpha: 0.4)),
                boxShadow: isOn
                    ? GlassTokens.glow(AppColors.auroraMint, intensity: 0.7)
                    : null,
              ),
            ),
          ),
          // Ảnh sản phẩm — Hero sang màn detail; Thiết bị điện OFF thì desaturate.
          // Với Khóa/Cổng (Lock/Gate), trạng thái Đóng (Close) là an toàn, luôn hiển thị rõ nét, không làm mờ/đen ảnh.
          Expanded(
            child: Center(
              child: Hero(
                tag: 'device-image-${device.id}',
                child: image != null
                    ? ColorFiltered(
                        colorFilter: (isOn || device.type == DeviceType.lock)
                            ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              )
                            : _greyscale,
                        child: AnimatedOpacity(
                          duration: GlassTokens.durationMed,
                          opacity: (isOn || device.type == DeviceType.lock) ? 1.0 : 0.55,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.asset(
                              image,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                DeviceVisuals.icon(device.type),
                                size: 56,
                                color: isOn
                                    ? accent
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        DeviceVisuals.icon(device.type),
                        size: 56,
                        color: isOn
                            ? accent
                            : Colors.white.withValues(alpha: 0.4),
                      ),
              ),
            ),
          ),
          Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: isOn ? 1 : 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _categoryLabel(l10n, device.type),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          _CardControl(device: device),
        ],
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, DeviceType type) =>
      switch (type) {
        DeviceType.light || DeviceType.ledRgb => l10n.filterLighting,
        DeviceType.thermostat ||
        DeviceType.fan ||
        DeviceType.speaker => l10n.filterElectric,
        DeviceType.sensor || DeviceType.camera => l10n.filterSensors,
        DeviceType.lock => l10n.filterOther,
      };
}

/// Control ở đáy card, đổi theo loại thiết bị. Tap control KHÔNG mở
/// màn detail (GestureDetector chặn event nổi bọt lên card).
class _CardControl extends ConsumerWidget {
  const _CardControl({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final controller = ref.read(devicesControllerProvider.notifier);
    final offline = device.status == DeviceStatus.offline;

    void toggle(bool value) {
      controller.updateDevice(device.id, DeviceCommand(isOn: value));
    }

    switch (device.type) {
      case DeviceType.light:
      case DeviceType.ledRgb:
      case DeviceType.fan:
      case DeviceType.speaker:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GlassToggle(value: device.isOn, onChanged: offline ? null : toggle),

            Text(
              device.isOn
                  ? (device.brightness != null
                        ? '${device.brightness}%'
                        : l10n.deviceOn)
                  : l10n.deviceOff,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        );

      case DeviceType.thermostat:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GlassToggle(value: device.isOn, onChanged: offline ? null : toggle),
            Text(
              device.isOn ? '${device.temperature ?? '--'}°C' : l10n.deviceOff,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        );

      case DeviceType.lock:
        return GlassStatusPill(
          icon: device.isOn ? Icons.lock_rounded : Icons.lock_open_rounded,
          label: device.isOn ? l10n.locked : l10n.unlocked,
          color: device.isOn ? AppColors.auroraMint : AppColors.auroraWarning,
        );

      case DeviceType.sensor:
      case DeviceType.camera:
        return GlassStatusPill(
          label:
              device.subtitle ?? (device.isOn ? l10n.deviceOn : l10n.deviceOff),
          color: device.isOn
              ? AppColors.auroraMint
              : Colors.white.withValues(alpha: 0.4),
        );
    }
  }
}
