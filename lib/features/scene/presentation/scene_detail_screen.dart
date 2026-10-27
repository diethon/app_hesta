import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_status_pill.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../data/scene_providers.dart';
import '../domain/scene.dart';
import 'scene_editor_screen.dart';
import 'scene_history_screen.dart';
import 'scene_icons.dart';

class SceneDetailScreen extends ConsumerStatefulWidget {
  const SceneDetailScreen({required this.scene, super.key});

  final Scene scene;

  @override
  ConsumerState<SceneDetailScreen> createState() => _SceneDetailScreenState();
}

class _SceneDetailScreenState extends ConsumerState<SceneDetailScreen> {
  late Scene _scene;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _scene = widget.scene;
  }

  Future<void> _execute() async {
    setState(() => _isExecuting = true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final success =
        await ref.read(scenesListProvider.notifier).executeScene(_scene.id);

    if (mounted) {
      setState(() => _isExecuting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã kích hoạt kịch bản: ${_scene.name}'
                : 'Kích hoạt thất bại',
          ),
          backgroundColor: success
              ? (isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight)
              : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa kịch bản "${_scene.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(scenesListProvider.notifier).deleteScene(_scene.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final schedulesAsync = ref.watch(sceneSchedulesProvider(_scene.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                title: 'Chi tiết ngữ cảnh',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.history_rounded,
                    tooltip: 'Lịch sử chạy',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SceneHistoryScreen(scene: _scene),
                      ),
                    ),
                  ),
                  GlassIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Chỉnh sửa',
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => SceneEditorScreen(scene: _scene),
                        ),
                      );
                      if (updated == true) {
                        ref.read(scenesListProvider.notifier).refresh();
                        Navigator.of(context).pop();
                      }
                    },
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
                  // Scene Hero Header Card
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    radius: AppRadius.hero,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: GlassTokens.glow(accent, intensity: 0.5),
                          ),
                          child: Icon(
                            SceneIcons.getIcon(_scene.icon),
                            color: accent,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _scene.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_scene.description != null &&
                            _scene.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _scene.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.onDarkMuted
                                  : AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassStatusPill(
                              label: '${_scene.actions.length} hành động',
                              color: accent,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            GlassStatusPill(
                              label: _scene.enabled ? 'Đang kích hoạt' : 'Đã tắt',
                              color: _scene.enabled
                                  ? (isDark
                                      ? AppColors.auroraMint
                                      : AppColors.auroraMintOnLight)
                                  : Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Execute Action Button
                        AppButton(
                          label: 'Chạy ngữ cảnh ngay',
                          icon: Icons.play_arrow_rounded,
                          isLoading: _isExecuting,
                          onPressed: _execute,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actions List Section
                  Text(
                    'HÀNH ĐỘNG ĐÃ THIẾT LẬP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    radius: AppRadius.card,
                    child: _scene.actions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Kịch bản này chưa có hành động nào.',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.onDarkFaint
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _scene.actions.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 16, color: Colors.white10),
                            itemBuilder: (context, index) {
                              final act = _scene.actions[index];
                              return Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.15),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.targetDeviceName,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Hành động: ${act.action}${act.value != null ? ' (${act.value})' : ''}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: isDark
                                                ? AppColors.onDarkMuted
                                                : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Schedules Section
                  Text(
                    'LỊCH TỰ ĐỘNG CHẠY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  schedulesAsync.when(
                    data: (schedules) => GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      radius: AppRadius.card,
                      child: schedules.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Chưa có lịch hẹn giờ nào.',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.onDarkFaint
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: schedules
                                  .map((sched) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.alarm_rounded,
                                                  size: 20, color: accent),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              Text(
                                                sched.time,
                                                style: theme.textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          GlassToggle(
                                            value: sched.enabled,
                                            onChanged: (_) {},
                                          ),
                                        ],
                                      ))
                                  .toList(),
                            ),
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Delete Scene Button
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      label: const Text(
                        'Xóa ngữ cảnh này',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onPressed: _confirmDelete,
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
