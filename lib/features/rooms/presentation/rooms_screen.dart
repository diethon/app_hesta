import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../devices/presentation/device_visuals.dart';
import '../../home/data/home_providers.dart';
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
                  icon: Icons.create_new_folder_outlined,
                  tooltip: 'Tạo phòng mới',
                  onTap: () => _showCreateRoomDialog(context, ref),
                ),
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

  Future<void> _showCreateRoomDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    String selectedIcon = 'default';
    const iconOptions = <(String, String, IconData)>[
      ('default', 'Mặc định', Icons.meeting_room_outlined),
      ('living', 'Phòng khách', Icons.weekend_outlined),
      ('bed', 'Phòng ngủ', Icons.bed_outlined),
      ('kitchen', 'Bếp', Icons.kitchen_outlined),
      ('bath', 'Phòng tắm', Icons.bathtub_outlined),
      ('garden', 'Sân vườn', Icons.nature_outlined),
    ];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final sheetTheme = Theme.of(sheetCtx);
          return GlassBottomSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sheetTheme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: sheetTheme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.create_new_folder_outlined,
                        color: sheetTheme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Text(
                        'Tạo Phòng Mới',
                        style: sheetTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: glassInputDecoration(
                    sheetCtx,
                    labelText: 'Tên phòng',
                    hintText: 'VD: Phòng khách, Phòng làm việc...',
                    prefixIcon: const Icon(
                      Icons.meeting_room_rounded,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Biểu tượng phòng',
                  style: sheetTheme.textTheme.labelMedium?.copyWith(
                    color: sheetTheme.colorScheme.onSurface.withValues(
                      alpha: 0.72,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: iconOptions.map((opt) {
                    return GlassFilterChip(
                      label: opt.$2,
                      icon: opt.$3,
                      selected: selectedIcon == opt.$1,
                      onTap: () {
                        setSheetState(() => selectedIcon = opt.$1);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: sheetTheme.colorScheme.onSurface
                              .withValues(alpha: 0.72),
                          side: BorderSide(
                            color: GlassTokens.borderSolid(
                              sheetTheme.brightness,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        onPressed: () => Navigator.of(sheetCtx).pop(false),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            return;
                          }
                          Navigator.of(sheetCtx).pop(true);
                        },
                        child: const Text(
                          'Tạo phòng',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final roomName = nameController.text.trim();
    nameController.dispose();
    if (confirmed != true || roomName.isEmpty) {
      return;
    }

    final homeId =
        ref.read(currentHomeIdProvider) ?? (kUseMockData ? 'mock-home-1' : '');
    if (homeId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Chưa xác định được ngôi nhà hiện tại.'),
          ),
        );
      }
      return;
    }

    try {
      await ref
          .read(roomRepositoryProvider)
          .createRoom(homeId: homeId, name: roomName, icon: selectedIcon);
      ref.invalidate(roomsForHomeProvider(homeId));
      ref.invalidate(remoteRoomsProvider);
      ref.invalidate(roomsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraMintOnLight,
            content: Text('Đã tạo phòng "$roomName"'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Không thể tạo phòng: $e'),
          ),
        );
      }
    }
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
    'living-room': (AppColors.auroraAccent, Icons.weekend_outlined),
    'bedroom': (AppColors.orbViolet, Icons.bed_outlined),
    'kitchen': (AppColors.auroraWarning, Icons.kitchen_outlined),
    'garage': (AppColors.orbAzure, Icons.garage_outlined),
    'bathroom': (AppColors.orbTeal, Icons.bathtub_outlined),
    'garden': (AppColors.auroraMint, Icons.nature_outlined),
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
