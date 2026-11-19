import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/studio.dart';
import '../../../core/widgets/glass/glass_segmented_control.dart';
import '../../recommendation/data/recommendation_providers.dart';
import '../../recommendation/presentation/recommendations_screen.dart';
import '../../scene/data/scene_providers.dart';
import '../../scene/presentation/scene_editor_screen.dart';
import '../../scene/presentation/scenes_screen.dart';
import '../data/automation_providers.dart';
import 'automation_rule_editor_screen.dart';
import 'automation_rules_screen.dart';

/// Trung tâm Tự động hoá: 3 tab Quy tắc / Ngữ cảnh / Gợi ý.
class AutomationScreen extends ConsumerStatefulWidget {
  const AutomationScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends ConsumerState<AutomationScreen> {
  late int _selectedTab;
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
  }

  Future<void> _handleRefresh() async {
    await HapticFeedback.lightImpact();
    if (_selectedTab == 0) {
      await ref.read(automationRulesListProvider.notifier).refresh();
    } else if (_selectedTab == 1) {
      await ref.read(scenesListProvider.notifier).refresh();
    } else {
      await ref.read(recommendationsListProvider.notifier).refresh();
      await ref.read(mlModelStatusProvider.notifier).refresh();
    }
  }

  Future<void> _triggerAIGenerate() async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _isGeneratingAI = true);

    final count = await ref
        .read(recommendationsListProvider.notifier)
        .generate();

    if (!mounted) return;
    setState(() => _isGeneratingAI = false);
    showStudioSnack(
      context,
      count > 0
          ? 'Tìm thấy $count gợi ý mới cho bạn.'
          : 'Chưa thấy thói quen nào lặp lại đủ rõ. Thử lại sau vài ngày nhé.',
    );
  }

  Future<void> _openEditor(Widget editor, Future<void> Function() refresh) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => editor),
    );
    if (mounted) unawaited(refresh());
  }

  Widget _buildFAB(Color accent) {
    final (IconData icon, String label, VoidCallback? onTap) = switch (_selectedTab) {
      0 => (
        Icons.add_rounded,
        'Tạo quy tắc',
        () => _openEditor(
          const AutomationRuleEditorScreen(),
          ref.read(automationRulesListProvider.notifier).refresh,
        ),
      ),
      1 => (
        Icons.add_rounded,
        'Thêm ngữ cảnh',
        () => _openEditor(
          const SceneEditorScreen(),
          ref.read(scenesListProvider.notifier).refresh,
        ),
      ),
      _ => (
        Icons.auto_awesome_outlined,
        _isGeneratingAI ? 'Đang tìm…' : 'Tìm gợi ý mới',
        _isGeneratingAI ? null : _triggerAIGenerate,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: _selectedTab == 2 && _isGeneratingAI
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = StudioColors.of(context).accent;

    final rulesCount =
        ref.watch(automationRulesListProvider).valueOrNull?.length ?? 0;
    final scenesCount = ref.watch(scenesListProvider).valueOrNull?.length ?? 0;
    final pendingRecsCount =
        ref
            .watch(recommendationsListProvider)
            .valueOrNull
            ?.where((r) => r.isPending)
            .length ??
        0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFAB(accent),
      body: StudioBackground(
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
                title: 'Tự động hoá',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Làm mới',
                    onTap: _handleRefresh,
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
                  // Glass Segmented Tab Switcher
                  GlassSegmentedControl(
                    selectedIndex: _selectedTab,
                    onChanged: (index) {
                      setState(() => _selectedTab = index);
                    },
                    segments: [
                      GlassSegment(
                        label: 'Quy tắc ($rulesCount)',
                        icon: Icons.alt_route_rounded,
                      ),
                      GlassSegment(
                        label: 'Ngữ cảnh ($scenesCount)',
                        icon: Icons.layers_rounded,
                      ),
                      GlassSegment(
                        label: pendingRecsCount > 0
                            ? 'Gợi ý ($pendingRecsCount)'
                            : 'Gợi ý',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tab Views
                  IndexedStack(
                    index: _selectedTab,
                    children: const [
                      AutomationRulesScreen(isEmbedded: true),
                      ScenesScreen(isEmbedded: true),
                      RecommendationsScreen(isEmbedded: true),
                    ],
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
