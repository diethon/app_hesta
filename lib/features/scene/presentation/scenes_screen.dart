import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_filter_chip.dart';
import '../../../core/widgets/glass/glass_status_pill.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/state_views.dart';
import '../data/scene_providers.dart';
import '../domain/scene.dart';
import 'scene_detail_screen.dart';
import 'scene_editor_screen.dart';
import 'scene_icons.dart';

class ScenesScreen extends ConsumerStatefulWidget {
  const ScenesScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  @override
  ConsumerState<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends ConsumerState<ScenesScreen> {
  String _selectedFilter = 'all'; // all, enabled, disabled
  String? _executingSceneId;

  Future<void> _executeScene(Scene scene, Color mint) async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _executingSceneId = scene.id);

    final success =
        await ref.read(scenesListProvider.notifier).executeScene(scene.id);

    if (!mounted) return;
    setState(() => _executingSceneId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                success
                    ? 'Đã kích hoạt ngữ cảnh: ${scene.name}'
                    : 'Không thể kích hoạt ngữ cảnh',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: success ? mint : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<Scene>> scenesAsync,
    bool isDark,
    Color accent,
    Color mint,
  ) {
    final theme = Theme.of(context);
    final allScenes = scenesAsync.valueOrNull ?? [];
    final enabledCount = allScenes.where((s) => s.enabled).length;
    final disabledCount = allScenes.where((s) => !s.enabled).length;
    final quickScenes = allScenes.where((s) => s.enabled).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick 1-Tap Scene Spotlight Carousel
        if (quickScenes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KÍCH HOẠT NHANH 1-CHẠM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.onDarkMuted : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${quickScenes.length} sẵn sàng',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.onDarkFaint : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: quickScenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, idx) {
                final sc = quickScenes[idx];
                final atmosphere = SceneIcons.getAtmosphere(sc.icon);
                final isRunning = _executingSceneId == sc.id;

                return _QuickSceneCard(
                  scene: sc,
                  atmosphere: atmosphere,
                  isRunning: isRunning,
                  onTap: () => _executeScene(sc, mint),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GlassFilterChip(
                label: 'Tất cả (${allScenes.length})',
                selected: _selectedFilter == 'all',
                onTap: () => setState(() => _selectedFilter = 'all'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đang bật ($enabledCount)',
                selected: _selectedFilter == 'enabled',
                onTap: () => setState(() => _selectedFilter = 'enabled'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đã tắt ($disabledCount)',
                selected: _selectedFilter == 'disabled',
                onTap: () => setState(() => _selectedFilter = 'disabled'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Scenes List
        scenesAsync.when(
          data: (scenes) {
            final filtered = scenes.where((s) {
              if (_selectedFilter == 'enabled') return s.enabled;
              if (_selectedFilter == 'disabled') return !s.enabled;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              final isFiltered = _selectedFilter != 'all';
              return Padding(
                padding: const EdgeInsets.only(top: 36, bottom: 44),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyView(
                        message: isFiltered
                            ? 'Không tìm thấy ngữ cảnh nào theo bộ lọc "$_selectedFilter".'
                            : 'Chưa có ngữ cảnh nào được tạo.\nHãy tạo ngữ cảnh đầu tiên để kích hoạt đồng loạt thiết bị!',
                        icon: Icons.layers_outlined,
                      ),
                      if (!isFiltered) ...[
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const SceneEditorScreen(),
                              ),
                            );
                            if (context.mounted) {
                              unawaited(
                                ref.read(scenesListProvider.notifier).refresh(),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tạo ngữ cảnh mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm + 2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: filtered
                  .map(
                    (scene) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SceneListItem(
                        scene: scene,
                        isExecuting: _executingSceneId == scene.id,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SceneDetailScreen(scene: scene),
                            ),
                          );
                          if (mounted) {
                            unawaited(
                              ref.read(scenesListProvider.notifier).refresh(),
                            );
                          }
                        },
                        onToggle: () {
                          HapticFeedback.selectionClick();
                          unawaited(
                            ref
                                .read(scenesListProvider.notifier)
                                .toggleScene(scene.id),
                          );
                        },
                        onExecute: () => _executeScene(scene, mint),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const GlassListSkeleton(itemCount: 3, itemHeight: 140),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 30),
            child: ErrorView(
              message: 'Không thể tải danh sách ngữ cảnh: $e',
              onRetry: () =>
                  unawaited(ref.read(scenesListProvider.notifier).refresh()),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenesAsync = ref.watch(scenesListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    if (widget.isEmbedded) {
      return _buildContent(context, scenesAsync, isDark, accent, mint);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SceneEditorScreen()),
            );
            if (mounted) {
              unawaited(ref.read(scenesListProvider.notifier).refresh());
            }
          },
          radius: AppRadius.pill,
          fill: accent,
          shadows: GlassTokens.glow(accent, intensity: 0.8),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Thêm ngữ cảnh',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
      body: AmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 68,
              flexibleSpace: GlassAppBar(
                title: 'Ngữ cảnh (Scenes)',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Làm mới',
                    onTap: () => unawaited(
                      ref.read(scenesListProvider.notifier).refresh(),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.navClearance * 1.5,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildContent(context, scenesAsync, isDark, accent, mint),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ Kích hoạt nhanh 1-chạm (Quick Scene Tile)
class _QuickSceneCard extends StatelessWidget {
  const _QuickSceneCard({
    required this.scene,
    required this.atmosphere,
    required this.isRunning,
    required this.onTap,
  });

  final Scene scene;
  final SceneAtmosphere atmosphere;
  final bool isRunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 145,
      child: GlassCard(
        onTap: isRunning ? null : onTap,
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            atmosphere.accentColor.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        shadows: GlassTokens.glow(atmosphere.accentColor, intensity: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: atmosphere.gradient
                          .map((c) => c.withValues(alpha: 0.35))
                          .toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: atmosphere.accentColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    atmosphere.icon,
                    size: 20,
                    color: atmosphere.accentColor,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: atmosphere.accentColor.withValues(alpha: 0.2),
                  ),
                  child: isRunning
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: atmosphere.accentColor,
                          ),
                        )
                      : Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: atmosphere.accentColor,
                        ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.onDark : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${scene.actions.length} thiết bị',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.onDarkMuted : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneListItem extends StatelessWidget {
  const _SceneListItem({
    required this.scene,
    required this.onTap,
    required this.onToggle,
    required this.onExecute,
    required this.isExecuting,
  });

  final Scene scene;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onExecute;
  final bool isExecuting;

  IconData _getDeviceIcon(String? type, String name) {
    final lowerName = name.toLowerCase();
    final lowerType = (type ?? '').toLowerCase();
    if (lowerName.contains('đèn') || lowerType.contains('light')) {
      return Icons.lightbulb_rounded;
    }
    if (lowerName.contains('lạnh') ||
        lowerName.contains('ac') ||
        lowerType.contains('climate')) {
      return Icons.ac_unit_rounded;
    }
    if (lowerName.contains('rèm') || lowerType.contains('curtain')) {
      return Icons.curtains_rounded;
    }
    if (lowerName.contains('khóa') || lowerType.contains('lock')) {
      return Icons.lock_rounded;
    }
    if (lowerName.contains('quạt') || lowerType.contains('fan')) {
      return Icons.mode_fan_off_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final atmosphere = SceneIcons.getAtmosphere(scene.icon);

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderGradient: scene.enabled
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                atmosphere.accentColor.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.06),
              ],
            )
          : null,
      shadows: scene.enabled
          ? GlassTokens.glow(atmosphere.accentColor, intensity: 0.15)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: scene.enabled
                        ? atmosphere.gradient
                            .map((c) => c.withValues(alpha: 0.35))
                            .toList()
                        : [
                            Colors.grey.withValues(alpha: 0.15),
                            Colors.grey.withValues(alpha: 0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: scene.enabled
                        ? atmosphere.accentColor.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: scene.enabled
                      ? GlassTokens.glow(atmosphere.accentColor, intensity: 0.25)
                      : null,
                ),
                child: Icon(
                  atmosphere.icon,
                  color: scene.enabled
                      ? atmosphere.accentColor
                      : (isDark ? AppColors.onDarkFaint : Colors.grey),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: scene.enabled
                            ? (isDark ? AppColors.onDark : AppColors.onSurface)
                            : (isDark
                                ? AppColors.onDarkMuted
                                : Colors.grey.shade600),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        GlassStatusPill(
                          label: '${scene.actions.length} hành động',
                          color: atmosphere.accentColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GlassStatusPill(
                          label: scene.enabled ? 'Đang bật' : 'Đã tắt',
                          color: scene.enabled ? mint : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GlassToggle(
                value: scene.enabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          if (scene.description != null && scene.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              scene.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.onDarkMuted : AppColors.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Device Chips with Micro-Icons
          if (scene.actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                ...scene.actions.take(3).map((act) {
                  final devIcon = _getDeviceIcon(
                    act.targetDeviceType,
                    act.targetDeviceName,
                  );
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          devIcon,
                          size: 12,
                          color: isDark
                              ? AppColors.onDarkMuted
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          act.targetDeviceName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.onDarkMuted
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (scene.actions.length > 3)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${scene.actions.length - 3}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Quick Execution Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chạm để xem chi tiết',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.onDarkFaint : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              InkWell(
                onTap: isExecuting ? null : onExecute,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: atmosphere.accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: atmosphere.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isExecuting)
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: atmosphere.accentColor,
                          ),
                        )
                      else
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: atmosphere.accentColor,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        isExecuting ? 'Đang chạy...' : 'Chạy ngay',
                        style: TextStyle(
                          color: atmosphere.accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
