import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_filter_chip.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/studio.dart';
import '../data/scene_providers.dart';
import '../domain/scene.dart';
import 'scene_detail_screen.dart';
import 'scene_editor_screen.dart';
import 'scene_icons.dart';
import 'scene_timer.dart';

class ScenesScreen extends ConsumerStatefulWidget {
  const ScenesScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  @override
  ConsumerState<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends ConsumerState<ScenesScreen> {
  String _selectedFilter = 'all'; // all, enabled, disabled
  String? _executingSceneId;

  Future<void> _executeScene(Scene scene) async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _executingSceneId = scene.id);

    final error = await ref
        .read(scenesListProvider.notifier)
        .executeScene(scene.id);

    if (!mounted) return;
    setState(() => _executingSceneId = null);
    showStudioSnack(
      context,
      error ?? 'Đã chạy "${scene.name}"',
      success: error == null,
    );
  }

  Future<void> _openEditor() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => const SceneEditorScreen()));
    if (mounted) unawaited(ref.read(scenesListProvider.notifier).refresh());
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<Scene>> scenesAsync,
  ) {
    final c = StudioColors.of(context);
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Chạy nhanh',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: quickScenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, idx) {
                final sc = quickScenes[idx];
                return _QuickSceneCard(
                  scene: sc,
                  isRunning: _executingSceneId == sc.id,
                  onTap: () => _executeScene(sc),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
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
                            ? (_selectedFilter == 'enabled'
                                  ? 'Không có kịch bản nào đang bật.'
                                  : 'Không có kịch bản nào đang tắt.')
                            : 'Chưa có kịch bản nào.\nTạo một kịch bản để điều khiển nhiều thiết bị chỉ với một chạm.',
                        icon: Icons.layers_outlined,
                      ),
                      if (!isFiltered) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _openEditor,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tạo kịch bản'),
                          style: FilledButton.styleFrom(
                            backgroundColor: c.accent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
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
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SceneListItem(
                        scene: scene,
                        isExecuting: _executingSceneId == scene.id,
                        onTap: () async {
                          await Navigator.of(context, rootNavigator: true).push(
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
                        onExecute: () => _executeScene(scene),
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
              message: 'Không tải được kịch bản. Kiểm tra kết nối rồi thử lại.',
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
    if (widget.isEmbedded) return _buildContent(context, scenesAsync);

    return StudioBackground(
      child: Builder(
        builder: (context) {
          final c = StudioColors.of(context);
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: Padding(
              // A nested Scaffold ignores the shell's floating nav bar; its height is in padding.bottom.
              padding: EdgeInsets.only(
                bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
              ),
              child: FloatingActionButton.extended(
                onPressed: _openEditor,
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                elevation: 2,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Thêm kịch bản',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
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
                    title: 'Kịch bản',
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
                      _buildContent(context, scenesAsync),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Ô "Chạy nhanh": chạm là chạy ngay.
class _QuickSceneCard extends StatelessWidget {
  const _QuickSceneCard({
    required this.scene,
    required this.isRunning,
    required this.onTap,
  });

  final Scene scene;
  final bool isRunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return SizedBox(
      width: 140,
      child: StudioCard(
        onTap: isRunning ? null : onTap,
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StudioIconTile(
                  icon: SceneIcons.getAtmosphere(scene.icon).icon,
                  size: 38,
                ),
                isRunning
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.accent,
                        ),
                      )
                    : Icon(Icons.play_circle_fill_rounded, color: c.accent),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${scene.actions.length} thiết bị',
                  style: TextStyle(fontSize: 12, color: c.muted),
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

  static IconData deviceIcon(String? type, String name) {
    final n = name.toLowerCase();
    final t = (type ?? '').toLowerCase();
    if (n.contains('đèn') || t.contains('light')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (n.contains('lạnh') ||
        n.contains('điều hòa') ||
        t.contains('climate') ||
        t.contains('ac')) {
      return Icons.ac_unit_rounded;
    }
    if (n.contains('rèm') || t.contains('curtain')) {
      return Icons.curtains_rounded;
    }
    if (n.contains('khóa') || t.contains('lock')) {
      return Icons.lock_outline_rounded;
    }
    if (n.contains('quạt') || t.contains('fan')) return Icons.air_rounded;
    return Icons.devices_other_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final on = scene.enabled;
    final devices = scene.actions.length;

    return StudioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudioIconTile(
                icon: SceneIcons.getAtmosphere(scene.icon).icon,
                active: on,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: on ? c.text : c.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$devices thiết bị · ${on ? 'Đang bật' : 'Đã tắt'}',
                      style: TextStyle(fontSize: 12.5, color: c.muted),
                    ),
                    if (scene.pendingRunAt != null)
                      SceneCountdown(
                        runAt: scene.pendingRunAt!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.accent,
                        ),
                      ),
                  ],
                ),
              ),
              Semantics(
                label: on ? 'Tắt kịch bản' : 'Bật kịch bản',
                child: GlassToggle(value: on, onChanged: (_) => onToggle()),
              ),
            ],
          ),
          if (scene.description != null && scene.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              scene.description!,
              style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (devices > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final act in scene.actions.take(3))
                  _DeviceChip(
                    icon: deviceIcon(
                      act.targetDeviceType,
                      act.targetDeviceName,
                    ),
                    label:
                        '${act.targetDeviceName}: ${describeAction(act.action, value: act.value)}',
                  ),
                if (devices > 3)
                  StudioTag(label: '+${devices - 3} khác', color: c.accent),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              // The backend refuses to run a switched-off scene, so do not offer it.
              onPressed: isExecuting || !on || devices == 0 ? null : onExecute,
              icon: isExecuting
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(isExecuting ? 'Đang chạy…' : 'Chạy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(
                  color: on ? c.accent.withValues(alpha: 0.4) : c.border,
                ),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: c.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
