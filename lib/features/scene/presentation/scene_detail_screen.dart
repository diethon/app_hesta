import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/studio.dart';
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
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _isExecuting = true);
    final error = await ref
        .read(scenesListProvider.notifier)
        .executeScene(_scene.id);
    if (!mounted) return;
    setState(() => _isExecuting = false);
    showStudioSnack(
      context,
      error ?? 'Đã chạy "${_scene.name}"',
      success: error == null,
    );
  }

  Future<void> _confirmDelete() async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá ngữ cảnh?'),
        content: Text('"${_scene.name}" sẽ bị xoá cùng lịch hẹn giờ của nó.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: StudioColors.of(ctx).danger,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(scenesListProvider.notifier).deleteScene(_scene.id);
      if (mounted) nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(sceneSchedulesProvider(_scene.id));

    return StudioBackground(
      child: Builder(
        builder: (context) {
          final c = StudioColors.of(context);
          final desc = _scene.description;
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
                    title: _scene.name,
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
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SceneEditorScreen(scene: _scene),
                                ),
                              );
                          if (updated == true && context.mounted) {
                            await ref
                                .read(scenesListProvider.notifier)
                                .refresh();
                            if (context.mounted) Navigator.of(context).pop();
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
                      // Thẻ đầu: icon, tên, trạng thái, nút chạy
                      StudioCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            StudioIconTile(
                              icon: SceneIcons.getAtmosphere(_scene.icon).icon,
                              size: 64,
                              active: _scene.enabled,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _scene.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: c.text,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_scene.actions.length} thiết bị · ${_scene.enabled ? 'Đang bật' : 'Đã tắt'}',
                              style: TextStyle(fontSize: 13, color: c.muted),
                            ),
                            if (desc != null && desc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: c.muted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isExecuting ? null : _execute,
                                icon: _isExecuting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  _isExecuting ? 'Đang chạy…' : 'Chạy ngay',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: c.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _SectionTitle('Thiết bị sẽ được điều khiển'),
                      StudioCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _scene.actions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    'Chưa có thiết bị nào.',
                                    style: TextStyle(color: c.faint),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final (i, act) in _scene.actions.indexed) ...[
                                    if (i > 0)
                                      Divider(height: 1, color: c.border),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          StudioIconTile(
                                            icon: _getDeviceIcon(
                                              act.targetDeviceType,
                                              act.targetDeviceName,
                                            ),
                                            size: 36,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              act.targetDeviceName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: c.text,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            describeAction(
                                              act.action,
                                              value: act.value,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: c.accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      _SectionTitle('Lịch tự động chạy'),
                      schedulesAsync.when(
                        data: (schedules) => StudioCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: schedules.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Chưa hẹn giờ. Bạn có thể thêm khi chỉnh sửa.',
                                      style: TextStyle(color: c.faint),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final sched in schedules)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.alarm_rounded,
                                              size: 20,
                                              color: sched.enabled
                                                  ? c.accent
                                                  : c.off,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              sched.time.length >= 5
                                                  ? sched.time.substring(0, 5)
                                                  : sched.time,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: c.text,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                describeDays(sched.repeatDays),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: c.muted,
                                                ),
                                              ),
                                            ),
                                            StudioTag(
                                              label: sched.enabled
                                                  ? 'Bật'
                                                  : 'Tắt',
                                              color: sched.enabled
                                                  ? c.on
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
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
                      const SizedBox(height: 28),

                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: c.danger,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text(
                            'Xoá ngữ cảnh',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _confirmDelete,
                        ),
                      ),
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

  IconData _getDeviceIcon(String? type, String name) {
    final n = name.toLowerCase();
    final t = (type ?? '').toLowerCase();
    if (n.contains('đèn') || t.contains('light')) return Icons.lightbulb_outline_rounded;
    if (n.contains('lạnh') || n.contains('điều hòa') || t.contains('climate')) {
      return Icons.ac_unit_rounded;
    }
    if (n.contains('rèm') || t.contains('curtain')) return Icons.curtains_rounded;
    if (n.contains('khóa') || t.contains('lock')) return Icons.lock_outline_rounded;
    if (n.contains('quạt') || t.contains('fan')) return Icons.mode_fan_off_outlined;
    return Icons.devices_other_rounded;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: StudioColors.of(context).text,
        ),
      ),
    );
  }
}
