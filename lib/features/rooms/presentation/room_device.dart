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
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../devices/presentation/device_visuals.dart';
import '../../home/data/home_providers.dart';
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
          type == DeviceType.speaker ||
          type == DeviceType.tv ||
          type == DeviceType.waterPump,
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
  bool _isSendingBatch = false;

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
                        tooltip: 'Quản lý phòng',
                        onTap: () => _showRoomOptionsSheet(context, roomName),
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
                        if (roomDevices.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Opacity(
                            opacity: _isSendingBatch ? 0.55 : 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GlassCard(
                                    onTap: _isSendingBatch
                                        ? null
                                        : () => _executeRoomBatch(true),
                                    radius: AppRadius.pill,
                                    blur: GlassTokens.blurSm,
                                    active: true,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm + 2,
                                    ),
                                    borderGradient: LinearGradient(
                                      colors: [
                                        AppColors.auroraMint.withValues(
                                          alpha: 0.65,
                                        ),
                                        AppColors.auroraMint.withValues(
                                          alpha: 0.16,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.power_rounded,
                                          size: 16,
                                          color: AppColors.auroraMint,
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.xs + 2,
                                        ),
                                        Text(
                                          'Bật cả phòng',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: AppColors.auroraMint,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: GlassCard(
                                    onTap: _isSendingBatch
                                        ? null
                                        : () => _executeRoomBatch(false),
                                    radius: AppRadius.pill,
                                    blur: GlassTokens.blurSm,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm + 2,
                                    ),
                                    borderGradient: LinearGradient(
                                      colors: [
                                        AppColors.auroraWarning.withValues(
                                          alpha: 0.65,
                                        ),
                                        AppColors.auroraWarning.withValues(
                                          alpha: 0.16,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.power_settings_new_rounded,
                                          size: 16,
                                          color: AppColors.auroraWarning,
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.xs + 2,
                                        ),
                                        Text(
                                          'Tắt cả phòng',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: AppColors.auroraWarning,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Future<void> _executeRoomBatch(bool turnOn) async {
    setState(() => _isSendingBatch = true);
    try {
      final action = turnOn ? 'TURN_ON' : 'TURN_OFF';
      final result = await ref
          .read(roomRepositoryProvider)
          .sendRoomCommand(roomId: widget.roomId, action: action);
      if (kUseMockData) {
        ref
            .read(devicesControllerProvider.notifier)
            .applyRoomPowerLocal(widget.roomId, turnOn);
      } else {
        await ref.read(devicesControllerProvider.notifier).refresh();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: result.isSuccess
                ? AppColors.auroraMintOnLight
                : AppColors.auroraWarning,
            content: Text(
              result.totalDevices == 0
                  ? 'Phòng chưa có thiết bị khả dụng.'
                  : '✓ ${result.successCount}/${result.totalDevices} thiết bị phản hồi',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Không thể điều khiển phòng: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingBatch = false);
      }
    }
  }

  ThemeData _roomDarkTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return theme;
    }
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

  void _showRoomOptionsSheet(BuildContext context, String currentName) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Theme(
        data: _roomDarkTheme(ctx),
        child: GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassOptionTile(
                icon: Icons.edit_rounded,
                color: AppColors.auroraMint,
                title: 'Đổi tên / Cập nhật phòng',
                subtitle: 'Đổi tên hiển thị của phòng "$currentName"',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showRenameRoomDialog(currentName);
                },
              ),
              Divider(
                height: 1,
                color: GlassTokens.borderSolid(Brightness.dark),
              ),
              GlassOptionTile(
                icon: Icons.delete_outline_rounded,
                color: AppColors.auroraError,
                titleColor: AppColors.auroraError,
                title: 'Xóa phòng (Safe Delete)',
                subtitle: 'Thiết bị bên trong vẫn được giữ lại',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteRoom(currentName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameRoomDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Theme(
        data: _roomDarkTheme(dialogCtx),
        child: GlassDialog(
          icon: Icons.edit_rounded,
          iconColor: AppColors.auroraMint,
          title: 'Cập nhật phòng',
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            style: const TextStyle(color: AppColors.onDark),
            decoration: glassInputDecoration(
              dialogCtx,
              labelText: 'Tên phòng mới',
              prefixIcon: const Icon(
                Icons.meeting_room_rounded,
                size: 20,
                color: AppColors.auroraAccent,
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.onDarkMuted,
                side: BorderSide(
                  color: GlassTokens.borderSolid(Brightness.dark),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.auroraAccent,
                foregroundColor: AppColors.auroraCanvasTop,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    final newName = controller.text.trim();
    controller.dispose();
    if (confirmed != true || newName.isEmpty) {
      return;
    }

    final homeId =
        ref.read(currentHomeIdProvider) ?? (kUseMockData ? 'mock-home-1' : '');
    if (homeId.isEmpty) {
      return;
    }

    try {
      await ref
          .read(roomRepositoryProvider)
          .updateRoom(homeId: homeId, roomId: widget.roomId, name: newName);
      ref.invalidate(roomsForHomeProvider(homeId));
      ref.invalidate(remoteRoomsProvider);
      ref.invalidate(roomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraMintOnLight,
            content: Text('Đã đổi tên phòng thành "$newName"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Không thể cập nhật phòng: $e'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteRoom(String currentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Theme(
        data: _roomDarkTheme(dialogCtx),
        child: GlassDialog(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.auroraError,
          title: 'Xóa phòng an toàn?',
          content: Text(
            'Bạn có chắc muốn xóa phòng "$currentName"?\n\nCác thiết bị trong phòng sẽ không bị xóa mà được chuyển sang trạng thái chưa gán phòng.',
            style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.4,
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.onDarkMuted,
                side: BorderSide(
                  color: GlassTokens.borderSolid(Brightness.dark),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.auroraError,
                foregroundColor: AppColors.auroraCanvasTop,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text(
                'Xóa phòng',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      return;
    }

    final homeId =
        ref.read(currentHomeIdProvider) ?? (kUseMockData ? 'mock-home-1' : '');
    if (homeId.isEmpty) {
      return;
    }

    try {
      await ref
          .read(roomRepositoryProvider)
          .deleteRoom(homeId: homeId, roomId: widget.roomId);
      ref
          .read(devicesControllerProvider.notifier)
          .detachRoomFromDevices(widget.roomId);
      ref.invalidate(roomsForHomeProvider(homeId));
      ref.invalidate(remoteRoomsProvider);
      ref.invalidate(roomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraMintOnLight,
            content: Text('Đã xóa phòng "$currentName"'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Không thể xóa phòng: $e'),
          ),
        );
      }
    }
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
                          opacity: (isOn || device.type == DeviceType.lock)
                              ? 1.0
                              : 0.55,
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
        DeviceType.speaker ||
        DeviceType.tv ||
        DeviceType.waterPump => l10n.filterElectric,
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
      case DeviceType.waterPump:
      case DeviceType.tv:
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
        if (device.isGate) {
          final isClosing = device.gateState == 'CLOSING';
          final isOpening = device.gateState == 'OPENING';
          final isStopped = device.gateState == 'STOPPED';
          final isClosed =
              device.gateState == 'CLOSED' ||
              (device.gateState == null && device.isOn);

          final gateLabel = isOpening
              ? 'Đang mở'
              : (isClosing
                    ? 'Đang đóng'
                    : (isStopped
                          ? 'Tạm dừng'
                          : (isClosed ? 'Đã đóng' : 'Đã mở')));

          final gateColor = (isOpening || isClosing)
              ? AppColors.auroraWarning
              : (isClosed ? AppColors.auroraMint : AppColors.orbTeal);

          return GlassStatusPill(
            icon: isClosed
                ? Icons.door_front_door_rounded
                : Icons.meeting_room_rounded,
            label: gateLabel,
            color: gateColor,
          );
        }
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
