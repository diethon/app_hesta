import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_status_pill.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/state_views.dart';
import '../../recommendation/presentation/recommendations_screen.dart';
import '../../scene/presentation/scenes_screen.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';
import 'automation_rule_detail_screen.dart';
import 'automation_rule_editor_screen.dart';

class AutomationRulesScreen extends ConsumerStatefulWidget {
  const AutomationRulesScreen({super.key});

  @override
  ConsumerState<AutomationRulesScreen> createState() =>
      _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends ConsumerState<AutomationRulesScreen> {
  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(automationRulesListProvider);
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
              MaterialPageRoute(
                builder: (_) => const AutomationRuleEditorScreen(),
              ),
            );
            await ref.read(automationRulesListProvider.notifier).refresh();
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
                title: 'Tự động hóa (Automation)',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Làm mới',
                    onTap: () =>
                        ref.read(automationRulesListProvider.notifier).refresh(),
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
                  // Quick Feature Navigation Cards (Recommendations & Scenes)
                  Row(
                    children: [
                      // AI Recommendation Banner
                      Expanded(
                        child: GlassCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecommendationsScreen(),
                            ),
                          ),
                          radius: AppRadius.card,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isDark
                                          ? AppColors.orbViolet
                                          : Colors.purple)
                                      .withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: isDark
                                      ? AppColors.orbViolet
                                      : Colors.purple,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Gợi ý AI',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Phân tích & đề xuất',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.onDarkMuted
                                      : AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Scenes Banner
                      Expanded(
                        child: GlassCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ScenesScreen(),
                            ),
                          ),
                          radius: AppRadius.card,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  Icons.layers_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Ngữ cảnh',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Kịch bản thiết bị',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.onDarkMuted
                                      : AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUY TẮC ĐANG HOẠT ĐỘNG',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  rulesAsync.when(
                    data: (rules) {
                      if (rules.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: EmptyView(
                            message:
                                'Chưa có quy tắc tự động hóa nào.\nHãy tạo quy tắc để hệ thống tự vận hành thông minh!',
                            icon: Icons.alt_route_rounded,
                          ),
                        );
                      }

                      return Column(
                        children: rules
                            .map((rule) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _RuleListItem(
                                    rule: rule,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AutomationRuleDetailScreen(
                                            rule: rule,
                                          ),
                                        ),
                                      );
                                      await ref
                                          .read(
                                            automationRulesListProvider.notifier,
                                          )
                                          .refresh();
                                    },
                                    onToggle: () {
                                      ref
                                          .read(
                                            automationRulesListProvider.notifier,
                                          )
                                          .toggleRule(rule.id);
                                    },
                                  ),
                                ))
                            .toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: ErrorView(
                        message: 'Không thể tải danh sách quy tắc: $e',
                        onRetry: () => ref
                            .read(automationRulesListProvider.notifier)
                            .refresh(),
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

class _RuleListItem extends StatelessWidget {
  const _RuleListItem({
    required this.rule,
    required this.onTap,
    required this.onToggle,
  });

  final AutomationRule rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;

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
            children: [
              Expanded(
                child: Text(
                  rule.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rule.enabled
                        ? (isDark ? AppColors.onDark : AppColors.onSurface)
                        : (isDark
                            ? AppColors.onDarkMuted
                            : Colors.grey.shade600),
                  ),
                ),
              ),
              GlassToggle(
                value: rule.enabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          if (rule.description != null && rule.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rule.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isDark ? AppColors.onDarkMuted : AppColors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Visual IF -> THEN block
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IF
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'IF',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rule.conditions.isEmpty
                            ? 'Luôn kích hoạt'
                            : rule.conditions
                                .map((c) =>
                                    '${c.deviceName ?? c.attribute} ${c.operatorSymbol} ${c.expectedValue}')
                                .join(' ${rule.conditions.first.logicalOperator} '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // THEN
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: mint.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'THEN',
                        style: TextStyle(
                          color: mint,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rule.actions.isEmpty
                            ? 'Không có hành động'
                            : rule.actions
                                .map((a) =>
                                    '${a.deviceName ?? a.sceneName ?? "Thiết bị"}: ${a.action}')
                                .join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassStatusPill(
                label: 'Loại: ${rule.triggerType}',
                color: accent,
              ),
              Row(
                children: [
                  Text(
                    'Chi tiết',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: accent),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
