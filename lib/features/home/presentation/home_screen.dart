import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/services/backend_resolver.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../devices/presentation/device_visuals.dart';
import 'widgets/hero_house_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(devicesControllerProvider);
    final mode = ref.watch(connectionModeControllerProvider);
    final session = ref.watch(authControllerProvider).session;
    final date = DateFormat(
      'EEEE, d MMMM',
      l10n.localeName,
    ).format(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            flexibleSpace: GlassAppBar(
              centerTitle: false,
              leading: GlassContainer(
                shape: BoxShape.circle,
                blur: GlassTokens.blurSm,
                child: SizedBox.square(
                  dimension: 40,
                  child: Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              title: l10n.appName,
              actions: [
                GlassIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add Device',
                  onTap: () => context.push('/add-device'),
                ),
                GlassIconButton(
                  icon: Icons.notifications_outlined,
                  tooltip: l10n.notifications,
                  onTap: () => context.go('/profile/notifications'),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.navClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConnectionBanner(mode: mode),
                    const SizedBox(height: AppSpacing.lg),
                    Builder(
                      builder: (context) {
                        final items = devices.valueOrNull ?? const <Device>[];
                        final sensor = items.cast<Device?>().firstWhere(
                          (d) => d?.rawType?.toUpperCase() == 'TEMP_HUMID_SENSOR',
                          orElse: () => items.cast<Device?>().firstWhere(
                            (d) =>
                                d?.type == DeviceType.sensor &&
                                (d?.temperature != null || d?.humidity != null),
                            orElse: () => null,
                          ),
                        );
                        return _GreetingHeader(
                          date: date,
                          name: session?.name ?? 'Alex',
                          temperature: sensor?.temperature,
                          humidity: sensor?.humidity,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    devices.when(
                      data: (items) => _DashboardContent(devices: items),
                      loading: () =>
                          const SizedBox(height: 420, child: LoadingView()),
                      error: (error, _) => SizedBox(
                        height: 420,
                        child: ErrorView(
                          message: error.toString(),
                          onRetry: () => ref
                              .read(devicesControllerProvider.notifier)
                              .load(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.date,
    required this.name,
    this.temperature,
    this.humidity,
  });

  final String date;
  final String name;
  final int? temperature;
  final int? humidity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.goodMorning(name),
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.thermostat_rounded,
                  color: AppColors.auroraWarning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  temperature != null ? '$temperature°C' : '--°C',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            if (humidity != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.orbTeal,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$humidity%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.devices});
  final List<Device> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final favorites = devices.where((d) => d.isFavorite).toList();

    if (devices.isEmpty) {
      return EmptyView(message: l10n.emptyTitle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HomeHeroCard(devices: devices),
        const SizedBox(height: AppSpacing.md),
        _StatusPillsRow(devices: devices),
        const SizedBox(height: AppSpacing.lg),

        // Lối vào Automation & Camera.
        _SectionLabel(label: l10n.quickAccess),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: GlassIconTile(
                    icon: Icons.auto_awesome_rounded,
                    label: l10n.automations,
                    subtitle: l10n.automationsSubtitle,
                    onTap: () => context.push('/automation'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: GlassIconTile(
                    icon: Icons.videocam_rounded,
                    label: l10n.camera,
                    subtitle: l10n.cameraSubtitle,
                    color: AppColors.orbTeal,
                    onTap: () => context.push('/camera'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(label: l10n.quickScenes),
        const SizedBox(height: AppSpacing.md),
        const _QuickScenes(),
        const SizedBox(height: AppSpacing.lg),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel(label: l10n.favoriteDevices),
            GestureDetector(
              onTap: () => context.go('/rooms'),
              child: Text(
                l10n.viewAll,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 560 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) =>
                  DeviceCard(device: favorites[index]),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(label: l10n.recentActivity),
        const SizedBox(height: AppSpacing.md),
        const _ActivityList(),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Hero card: trạng thái nhà + mô hình 3D isometric tràn nhẹ ra mép
// ─────────────────────────────────────────────────────────────────────
class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.devices});
  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    final locks = devices.where((d) => d.type == DeviceType.lock);
    final allSecured = locks.isNotEmpty && locks.every((d) => d.isOn);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassContainer(
          radius: AppRadius.hero,
          blur: GlassTokens.blurLg,
          shadows: GlassTokens.shadowSoft,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mint.withValues(alpha: 0.15),
                        boxShadow: GlassTokens.glow(mint, intensity: 0.4),
                      ),
                      child: Icon(
                        allSecured
                            ? Icons.verified_user_rounded
                            : Icons.gpp_maybe_rounded,
                        color: allSecured ? mint : AppColors.auroraWarning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      allSecured ? l10n.homeSecure : l10n.homeAttention,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      allSecured
                          ? l10n.homeSecureSubtitle
                          : l10n.homeAttentionSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Chừa chỗ cho mô hình 3D tràn ra mép phải.
              const Expanded(flex: 4, child: SizedBox(height: 170)),
            ],
          ),
        ),
        // Mô hình 3D nổi phía trên, tràn nhẹ khỏi mép thẻ.
        Positioned(
          right: -AppSpacing.md,
          top: -AppSpacing.md,
          bottom: -AppSpacing.xs,
          width: 190,
          child: IgnorePointer(
            ignoring: false,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: AppShadows.heroModel(theme.brightness),
                borderRadius: BorderRadius.circular(AppRadius.hero),
              ),
              child: const HeroHouseModel(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// 3 pill số liệu thật bên dưới hero
// ─────────────────────────────────────────────────────────────────────
class _StatusPillsRow extends StatelessWidget {
  const _StatusPillsRow({required this.devices});
  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    final locks = devices.where((d) => d.type == DeviceType.lock).toList();
    final openLocks = locks.where((d) => !d.isOn).length;
    final lights = devices.where((d) => d.type == DeviceType.light).toList();
    final lightsOn = lights.where((d) => d.isOn).length;
    final cameras = devices.where((d) => d.type == DeviceType.camera);
    final armed = cameras.isNotEmpty && cameras.every((d) => d.isOn);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          GlassStatusPill(
            icon: Icons.door_front_door_outlined,
            value: '$openLocks/${locks.length}',
            label: l10n.doorsOpen,
            color: openLocks == 0 ? mint : AppColors.auroraWarning,
            onTap: () => context.go('/rooms'),
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassStatusPill(
            icon: Icons.lightbulb_outline_rounded,
            value: '$lightsOn/${lights.length}',
            label: l10n.lightsOn,
            color: AppColors.auroraWarning,
            onTap: () => context.go('/rooms'),
          ),
          const SizedBox(width: AppSpacing.sm),
          GlassStatusPill(
            icon: Icons.shield_outlined,
            label: armed ? l10n.systemArmed : l10n.systemDisarmed,
            color: armed ? mint : AppColors.auroraWarning,
            onTap: () => context.push('/camera'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Quick Scenes
// ─────────────────────────────────────────────────────────────────────
class _QuickScenes extends StatelessWidget {
  const _QuickScenes();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scenes = [
      (Icons.power_settings_new_rounded, l10n.sceneAllOff, false),
      (Icons.home_rounded, l10n.sceneArriveHome, true),
      (Icons.movie_rounded, l10n.sceneMovieNight, false),
      (Icons.bedtime_rounded, l10n.sceneGoodNight, false),
      (Icons.add_rounded, l10n.sceneAdd, false),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          return _SceneButton(
            icon: scene.$1,
            label: scene.$2,
            isActive: scene.$3,
          );
        },
      ),
    );
  }
}

class _SceneButton extends StatelessWidget {
  const _SceneButton({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      children: [
        GlassCard(
          onTap: () {},
          active: isActive,
          radius: AppRadius.lg + 2,
          padding: EdgeInsets.zero,
          fill: isActive ? accent : null,
          shadows: isActive ? GlassTokens.glow(accent, intensity: 0.6) : null,
          semanticLabel: label,
          child: SizedBox.square(
            dimension: 64,
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: isActive ? 1 : 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Device Card (favorites)
// ─────────────────────────────────────────────────────────────────────
class DeviceCard extends ConsumerWidget {
  const DeviceCard({required this.device, super.key});
  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = DeviceVisuals.accent(device.type, theme.brightness);

    return GlassCard(
      onTap: () => context.go('/home/devices/${device.id}'),
      active: device.isOn,
      shadows: device.isOn ? GlassTokens.glow(accent, intensity: 0.25) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DeviceThumb(device: device, accent: accent),
              if (device.type == DeviceType.lock)
                Text(
                  device.isOn ? l10n.locked : l10n.unlocked,
                  style: theme.textTheme.labelSmall?.copyWith(color: accent),
                )
              else
                GlassToggle(
                  value: device.isOn,
                  onChanged: device.status == DeviceStatus.offline
                      ? null
                      : (value) {
                          ref
                              .read(devicesControllerProvider.notifier)
                              .updateDevice(
                                device.id,
                                DeviceCommand(isOn: value),
                              );
                        },
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                device.subtitle ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DeviceCardFooter(device: device, accent: accent),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thumbnail ảnh sản phẩm cho card yêu thích; OFF thì desaturate + mờ.
/// Chưa có asset thì fallback về icon tile tròn như cũ.
class _DeviceThumb extends StatelessWidget {
  const _DeviceThumb({required this.device, required this.accent});

  final Device device;
  final Color accent;

  static const _size = 48.0;
  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = DeviceVisuals.productImage(device);
    final isOn = device.isOn;

    if (image == null) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn
              ? accent.withValues(alpha: 0.15)
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        child: Icon(
          DeviceVisuals.icon(device.type),
          color: isOn
              ? accent
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 22,
        ),
      );
    }

    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: (isOn || device.type == DeviceType.lock)
            ? accent.withValues(alpha: 0.12)
            : theme.colorScheme.onSurface.withValues(alpha: 0.06),
      ),
      child: ColorFiltered(
        colorFilter: (isOn || device.type == DeviceType.lock)
            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
            : _greyscale,
        child: AnimatedOpacity(
          duration: GlassTokens.durationMed,
          opacity: (isOn || device.type == DeviceType.lock) ? 1.0 : 0.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                DeviceVisuals.icon(device.type),
                size: 22,
                color: isOn
                    ? accent
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCardFooter extends ConsumerWidget {
  const _DeviceCardFooter({required this.device, required this.accent});

  final Device device;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (device.type == DeviceType.light && device.brightness != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: LinearProgressIndicator(
          value: device.brightness! / 100,
          minHeight: 6,
          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation(accent),
        ),
      );
    }

    if (device.type == DeviceType.thermostat && device.temperature != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TempButton(
            icon: Icons.remove,
            onPressed: () => ref
                .read(devicesControllerProvider.notifier)
                .updateDevice(
                  device.id,
                  DeviceCommand(
                    temperature: ((device.temperature ?? 20) - 1).clamp(16, 30),
                  ),
                ),
          ),
          Text('${device.temperature}°', style: theme.textTheme.titleMedium),
          _TempButton(
            icon: Icons.add,
            onPressed: () => ref
                .read(devicesControllerProvider.notifier)
                .updateDevice(
                  device.id,
                  DeviceCommand(
                    temperature: ((device.temperature ?? 20) + 1).clamp(16, 30),
                  ),
                ),
          ),
        ],
      );
    }

    if (device.type == DeviceType.lock) {
      return GlassStatusPill(
        icon: device.isOn ? Icons.lock_rounded : Icons.lock_open_rounded,
        label: device.isOn ? l10n.secured : l10n.unlocked,
        color: accent,
      );
    }

    return Text(
      device.status == DeviceStatus.offline
          ? l10n.deviceOffline
          : (device.isOn ? l10n.deviceOn : l10n.deviceOff),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

class _TempButton extends StatelessWidget {
  const _TempButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Recent Activity
// ─────────────────────────────────────────────────────────────────────
class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final activities = [
      (Icons.person_rounded, l10n.activityArrived, '08:30'),
      (Icons.light_mode_rounded, l10n.activityMorningRoutine, '07:00'),
      (Icons.security_rounded, l10n.activityPatioMotion, '03:12'),
    ];

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (final (index, activity) in activities.indexed) ...[
            if (index > 0)
              Divider(
                height: AppSpacing.md,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  child: Icon(
                    activity.$1,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(activity.$2, style: theme.textTheme.labelMedium),
                ),
                Text(
                  activity.$3,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

// ─────────────────────────────────────────────────────────────────────
// Connection Banner
// ─────────────────────────────────────────────────────────────────────
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.mode});
  final ConnectionMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = switch (mode) {
      ConnectionMode.edge => l10n.localMode,
      ConnectionMode.cloud => l10n.cloudMode,
      ConnectionMode.offline => l10n.offline,
    };
    final icon = switch (mode) {
      ConnectionMode.edge => Icons.router_rounded,
      ConnectionMode.cloud => Icons.cloud_done_rounded,
      ConnectionMode.offline => Icons.cloud_off_rounded,
    };
    final color = switch (mode) {
      ConnectionMode.offline => theme.colorScheme.error,
      _ => theme.colorScheme.primary,
    };

    return GlassContainer(
      radius: AppRadius.lg,
      blur: GlassTokens.blurSm,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
