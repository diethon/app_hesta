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
import '../../../core/widgets/glass/glass_segmented_control.dart';
import '../../recommendation/data/recommendation_providers.dart';
import '../../recommendation/presentation/recommendations_screen.dart';
import '../../scene/data/scene_providers.dart';
import '../../scene/presentation/scene_editor_screen.dart';
import '../../scene/presentation/scenes_screen.dart';
import '../data/automation_providers.dart';
import 'automation_rule_editor_screen.dart';
import 'automation_rules_screen.dart';

/// Trung tâm Tự động hóa thông minh HESTA.
/// Tích hợp đồng bộ 3 trụ cột:
/// 1. Quy tắc tự động (Automation Rules - IF/THEN)
/// 2. Ngữ cảnh thiết bị (Scenes - Kịch bản 1-chạm)
/// 3. Đề xuất AI (Recommendations - Thói quen từ mô hình ML)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _isGeneratingAI = true);

    final count =
        await ref.read(recommendationsListProvider.notifier).generate();

    if (mounted) {
      setState(() => _isGeneratingAI = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Mô hình ML đã phát hiện và tạo $count đề xuất mới!'
                : 'Không có thói quen lặp lại nào đạt ngưỡng tin cậy >= 80% lúc này.',
          ),
          backgroundColor: count > 0 ? mint : AppColors.auroraWarning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Widget? _buildFAB(BuildContext context, Color accent, Color mint, bool isDark) {
    if (_selectedTab == 0) {
      // FAB Tạo quy tắc mới
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const AutomationRuleEditorScreen(),
              ),
            );
            if (context.mounted) {
              unawaited(
                ref.read(automationRulesListProvider.notifier).refresh(),
              );
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
                'Tạo quy tắc mới',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedTab == 1) {
      // FAB Thêm ngữ cảnh
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SceneEditorScreen()),
            );
            if (context.mounted) {
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
      );
    } else {
      // FAB Quét đề xuất AI
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          onTap: _isGeneratingAI ? null : _triggerAIGenerate,
          radius: AppRadius.pill,
          fill: (isDark ? AppColors.orbViolet : Colors.purple),
          shadows: GlassTokens.glow(
            isDark ? AppColors.orbViolet : Colors.purple,
            intensity: 0.8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGeneratingAI)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _isGeneratingAI ? 'Đang phân tích...' : 'Quét dữ liệu AI',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    final rulesCount =
        ref.watch(automationRulesListProvider).valueOrNull?.length ?? 0;
    final scenesCount =
        ref.watch(scenesListProvider).valueOrNull?.length ?? 0;
    final pendingRecsCount = ref
            .watch(recommendationsListProvider)
            .valueOrNull
            ?.where((r) => r.isPending)
            .length ??
        0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFAB(context, accent, mint, isDark),
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
                title: 'Tự động hóa (Automations)',
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
                  // Smart Automation Telemetry Summary
                  GlassCard(
                    radius: AppRadius.card,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TelemetryStat(
                          icon: Icons.alt_route_rounded,
                          label: 'Quy tắc chạy',
                          count: '$rulesCount',
                          color: accent,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                        _TelemetryStat(
                          icon: Icons.layers_rounded,
                          label: 'Ngữ cảnh',
                          count: '$scenesCount',
                          color: const Color(0xFFFBBF24),
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                        _TelemetryStat(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Gợi ý AI',
                          count: '$pendingRecsCount',
                          color: isDark ? AppColors.orbViolet : Colors.purple,
                          isSelected: _selectedTab == 2,
                          highlight: pendingRecsCount > 0,
                          onTap: () => setState(() => _selectedTab = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                            ? 'Gợi ý AI ($pendingRecsCount)'
                            : 'Gợi ý AI',
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

class _TelemetryStat extends StatelessWidget {
  const _TelemetryStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    this.highlight = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final bool isSelected;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? color : AppColors.onDarkFaint,
                ),
                const SizedBox(width: 5),
                Text(
                  count,
                  style: TextStyle(
                    color: isSelected ? color : (isDark ? AppColors.onDark : AppColors.onSurface),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (highlight) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: GlassTokens.glow(color, intensity: 0.5),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isSelected ? color : AppColors.onDarkMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

