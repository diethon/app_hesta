import 'dart:async';

import 'package:flutter/material.dart';
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
  const ScenesScreen({super.key});

  @override
  ConsumerState<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends ConsumerState<ScenesScreen> {
  String _selectedFilter = 'all'; // all, enabled, disabled
  String? _executingSceneId;

  @override
  Widget build(BuildContext context) {
    final scenesAsync = ref.watch(scenesListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

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
                    onTap: () =>
                        unawaited(ref.read(scenesListProvider.notifier).refresh()),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.navClearance * 1.5,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GlassFilterChip(
                          label: 'Tất cả',
                          selected: _selectedFilter == 'all',
                          onTap: () =>
                              setState(() => _selectedFilter = 'all'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GlassFilterChip(
                          label: 'Đang bật',
                          selected: _selectedFilter == 'enabled',
                          onTap: () =>
                              setState(() => _selectedFilter = 'enabled'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GlassFilterChip(
                          label: 'Đã tắt',
                          selected: _selectedFilter == 'disabled',
                          onTap: () =>
                              setState(() => _selectedFilter = 'disabled'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  scenesAsync.when(
                    data: (scenes) {
                      final filtered = scenes.where((s) {
                        if (_selectedFilter == 'enabled') return s.enabled;
                        if (_selectedFilter == 'disabled') return !s.enabled;
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: EmptyView(
                            message: _selectedFilter == 'all'
                                ? 'Chưa có ngữ cảnh nào.\nHãy tạo ngữ cảnh đầu tiên để tự động hóa ngôi nhà!'
                                : 'Không tìm thấy ngữ cảnh phù hợp bộ lọc.',
                            icon: Icons.auto_awesome_rounded,
                          ),
                        );
                      }

                      return Column(
                        children: filtered
                            .map((scene) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _SceneListItem(
                                    scene: scene,
                                    isExecuting:
                                        _executingSceneId == scene.id,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SceneDetailScreen(scene: scene),
                                        ),
                                      );
                                      if (mounted) {
                                        unawaited(
                                          ref
                                              .read(scenesListProvider.notifier)
                                              .refresh(),
                                        );
                                      }
                                    },
                                    onToggle: () {
                                      unawaited(
                                        ref
                                            .read(scenesListProvider.notifier)
                                            .toggleScene(scene.id),
                                      );
                                    },
                                    onExecute: () async {
                                      setState(
                                          () => _executingSceneId = scene.id);
                                      final success = await ref
                                          .read(scenesListProvider.notifier)
                                          .executeScene(scene.id);
                                      if (!context.mounted) return;
                                      setState(() =>
                                          _executingSceneId = null);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Đã kích hoạt kịch bản: ${scene.name}'
                                                : 'Không thể kích hoạt kịch bản',
                                          ),
                                          backgroundColor: success
                                              ? (isDark
                                                  ? AppColors.auroraMint
                                                  : AppColors.auroraMintOnLight)
                                              : AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ))
                            .toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: ErrorView(
                        message: 'Không thể tải danh sách ngữ cảnh: $e',
                        onRetry: () =>
                            unawaited(ref.read(scenesListProvider.notifier).refresh()),
                      ),
                    ),
                  ),
                ]),
              ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                    colors: [
                      scene.enabled
                          ? accent.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.15),
                      scene.enabled
                          ? accent.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: scene.enabled
                        ? accent.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  SceneIcons.getIcon(scene.icon),
                  color: scene.enabled
                      ? accent
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
                        fontWeight: FontWeight.w600,
                        color: scene.enabled
                            ? (isDark ? AppColors.onDark : AppColors.onSurface)
                            : (isDark
                                ? AppColors.onDarkMuted
                                : Colors.grey.shade600),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        GlassStatusPill(
                          label: '${scene.actions.length} hành động',
                          color: accent,
                        ),
                        if (scene.enabled) ...[
                          const SizedBox(width: AppSpacing.xs),
                          GlassStatusPill(
                            label: 'Kích hoạt',
                            color: mint,
                          ),
                        ],
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
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chạm để xem chi tiết',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.onDarkFaint : Colors.grey.shade600,
                ),
              ),
              InkWell(
                onTap: isExecuting ? null : onExecute,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isExecuting)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      else
                        Icon(Icons.play_arrow_rounded, size: 16, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        isExecuting ? 'Đang chạy...' : 'Chạy ngay',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
