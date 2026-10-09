import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../devices/presentation/device_visuals.dart';
import '../data/room_providers.dart';
import '../domain/room.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rooms = ref.watch(roomsProvider);
    final totalDevices = rooms.fold<int>(0, (sum, r) => sum + r.deviceCount);

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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.navClearance,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  l10n.yourRooms,
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.totalDevicesConnected(totalDevices),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Card an ninh: lối vào Camera.
                _SecurityCameraCard(onTap: () => context.push('/camera')),
                const SizedBox(height: AppSpacing.md),

                ...rooms.map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RoomCard(room: room),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ kính an ninh — lối vào màn Camera từ tab Rooms.
class _SecurityCameraCard extends StatelessWidget {
  const _SecurityCameraCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticLabel: l10n.securityCameras,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: mint.withValues(alpha: 0.15),
              boxShadow: GlassTokens.glow(mint, intensity: 0.35),
            ),
            child: Icon(Icons.videocam_rounded, color: mint, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.securityCameras, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mint,
                        boxShadow: GlassTokens.glow(mint, intensity: 0.6),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.camerasLive,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final Room room;

  // Màu nhấn + icon theo phòng để card không đơn điệu.
  static const _roomConfig = <String, (Color, IconData)>{
    'living-room': (Color(0xFFC4956A), Icons.weekend_outlined),
    'bedroom': (Color(0xFF7EA8C4), Icons.bed_outlined),
    'kitchen': (Color(0xFF5A8A72), Icons.kitchen_outlined),
    'garage': (Color(0xFF8A8A9A), Icons.garage_outlined),
    'bathroom': (Color(0xFF5AA0C4), Icons.bathtub_outlined),
    'garden': (Color(0xFF5A8A52), Icons.nature_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final canonical = DeviceVisuals.canonicalRoomType(
      room.slug.isNotEmpty ? room.slug : room.name,
    );
    final config =
        _roomConfig[canonical] ??
        (theme.colorScheme.primary, Icons.meeting_room_outlined);
    final tint = config.$1;
    final icon = config.$2;
    final hasActive = room.activeCount > 0;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    final image = DeviceVisuals.roomCardImage(
      room.slug.isNotEmpty ? room.slug : room.name,
    );

    return GlassCard(
      onTap: () => context.push('/rooms/${room.id}'),
      radius: AppRadius.card,
      padding: EdgeInsets.zero,
      active: hasActive,
      shadows: hasActive ? GlassTokens.glow(tint, intensity: 0.25) : null,
      semanticLabel: room.name,
      child: SizedBox(
        height: 188,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh phòng full-bleed; fallback vệt màu + icon nếu thiếu ảnh.
              if (image != null)
                Image.asset(image, fit: BoxFit.cover)
              else ...[
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tint.withValues(alpha: isDark ? 0.35 : 0.3),
                          tint.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Icon(
                    icon,
                    size: 56,
                    color: tint.withValues(alpha: isDark ? 0.8 : 0.9),
                  ),
                ),
              ],
              // Scrim tối dần ở đáy để chữ trắng đủ contrast trên ảnh.
              if (image != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 0.7, 1],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      room.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: image != null ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasActive
                                ? mint
                                : (image != null
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.3,
                                        )),
                            boxShadow: hasActive
                                ? GlassTokens.glow(mint, intensity: 0.6)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Text(
                          l10n.roomDevicesSummary(
                            room.deviceCount,
                            room.activeCount,
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: image != null
                                ? Colors.white.withValues(alpha: 0.85)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.65,
                                  ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${room.temperature}°',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: image != null
                                ? Colors.white.withValues(alpha: 0.75)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: image != null
                              ? Colors.white.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
