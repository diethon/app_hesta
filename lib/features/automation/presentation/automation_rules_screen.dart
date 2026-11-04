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
import '../../recommendation/presentation/recommendations_screen.dart';
import '../../scene/presentation/scenes_screen.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';
import 'automation_rule_detail_screen.dart';
import 'automation_rule_editor_screen.dart';

class AutomationRulesScreen extends ConsumerStatefulWidget {
  const AutomationRulesScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  @override
  ConsumerState<AutomationRulesScreen> createState() =>
      _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends ConsumerState<AutomationRulesScreen> {
  String _selectedFilter = 'all'; // all, SENSOR, SCHEDULE, EVENT, enabled, disabled

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<AutomationRule>> rulesAsync,
    bool isDark,
    Color accent,
    Color mint,
  ) {
    final theme = Theme.of(context);
    final allRules = rulesAsync.valueOrNull ?? [];
    final sensorCount =
        allRules.where((r) => r.triggerType.toUpperCase() == 'SENSOR').length;
    final scheduleCount =
        allRules.where((r) => r.triggerType.toUpperCase() == 'SCHEDULE').length;
    final eventCount =
        allRules.where((r) => r.triggerType.toUpperCase() == 'EVENT').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Navigation Banners when NOT embedded
        if (!widget.isEmbedded) ...[
          Row(
            children: [
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
                          color: (isDark ? AppColors.orbViolet : Colors.purple)
                              .withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: isDark ? AppColors.orbViolet : Colors.purple,
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
                        'Kịch bản 1-chạm',
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
        ],

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GlassFilterChip(
                label: 'Tất cả (${allRules.length})',
                selected: _selectedFilter == 'all',
                onTap: () => setState(() => _selectedFilter = 'all'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Cảm biến ($sensorCount)',
                selected: _selectedFilter == 'SENSOR',
                onTap: () => setState(() => _selectedFilter = 'SENSOR'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Lịch biểu ($scheduleCount)',
                selected: _selectedFilter == 'SCHEDULE',
                onTap: () => setState(() => _selectedFilter = 'SCHEDULE'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Sự kiện ($eventCount)',
                selected: _selectedFilter == 'EVENT',
                onTap: () => setState(() => _selectedFilter = 'EVENT'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đang bật',
                selected: _selectedFilter == 'enabled',
                onTap: () => setState(() => _selectedFilter = 'enabled'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đã tắt',
                selected: _selectedFilter == 'disabled',
                onTap: () => setState(() => _selectedFilter = 'disabled'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Rules List
        rulesAsync.when(
          data: (rules) {
            final filtered = rules.where((r) {
              if (_selectedFilter == 'SENSOR') {
                return r.triggerType.toUpperCase() == 'SENSOR';
              }
              if (_selectedFilter == 'SCHEDULE') {
                return r.triggerType.toUpperCase() == 'SCHEDULE';
              }
              if (_selectedFilter == 'EVENT') {
                return r.triggerType.toUpperCase() == 'EVENT';
              }
              if (_selectedFilter == 'enabled') return r.enabled;
              if (_selectedFilter == 'disabled') return !r.enabled;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              final isFiltered = _selectedFilter != 'all';
              return Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyView(
                        message: isFiltered
                            ? 'Không tìm thấy quy tắc nào theo bộ lọc "$_selectedFilter".'
                            : 'Chưa có quy tắc tự động hóa nào.\nHãy tạo quy tắc để ngôi nhà tự động vận hành thông minh!',
                        icon: Icons.alt_route_rounded,
                      ),
                      if (!isFiltered) ...[
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AutomationRuleEditorScreen(),
                              ),
                            );
                            if (context.mounted) {
                              unawaited(
                                ref
                                    .read(automationRulesListProvider.notifier)
                                    .refresh(),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tạo quy tắc mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
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
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RuleListItem(
                        rule: rule,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AutomationRuleDetailScreen(rule: rule),
                            ),
                          );
                          if (mounted) {
                            unawaited(
                              ref
                                  .read(automationRulesListProvider.notifier)
                                  .refresh(),
                            );
                          }
                        },
                        onToggle: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(automationRulesListProvider.notifier)
                              .toggleRule(rule.id);
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const GlassListSkeleton(itemCount: 3, itemHeight: 160),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 30),
            child: ErrorView(
              message: 'Không thể tải danh sách quy tắc: $e',
              onRetry: () =>
                  ref.read(automationRulesListProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(automationRulesListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    if (widget.isEmbedded) {
      return _buildContent(context, rulesAsync, isDark, accent, mint);
    }

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
            if (mounted) {
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
                  _buildContent(context, rulesAsync, isDark, accent, mint),
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

  IconData _triggerIcon(String type) {
    switch (type.toUpperCase()) {
      case 'SCHEDULE':
        return Icons.schedule_rounded;
      case 'EVENT':
        return Icons.flash_on_rounded;
      case 'SENSOR':
      default:
        return Icons.sensors_rounded;
    }
  }

  Color _triggerColor(String type, Color defaultAccent) {
    switch (type.toUpperCase()) {
      case 'SCHEDULE':
        return const Color(0xFFFBBF24); // Amber
      case 'EVENT':
        return const Color(0xFFA855F7); // Violet
      case 'SENSOR':
      default:
        return const Color(0xFF38BDF8); // Sky Blue
    }
  }

  String _triggerLabel(String type) {
    switch (type.toUpperCase()) {
      case 'SCHEDULE':
        return 'LỊCH BIỂU';
      case 'EVENT':
        return 'SỰ KIỆN';
      case 'SENSOR':
      default:
        return 'CẢM BIẾN';
    }
  }

  String _formatAction(RuleAction act) {
    final target = act.deviceName ?? act.sceneName ?? 'Thiết bị';
    final action = act.action;
    final params = act.parameters.isNotEmpty
        ? ' (${act.parameters.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
        : '';
    return '$target: $action$params';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final trigColor = _triggerColor(rule.triggerType, accent);

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderGradient: rule.enabled
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                trigColor.withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0.06),
              ],
            )
          : null,
      shadows: rule.enabled
          ? GlassTokens.glow(trigColor, intensity: 0.15)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      (rule.enabled ? trigColor : Colors.grey)
                          .withValues(alpha: 0.28),
                      (rule.enabled ? trigColor : Colors.grey)
                          .withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: (rule.enabled ? trigColor : Colors.grey)
                        .withValues(alpha: 0.35),
                  ),
                  boxShadow: rule.enabled
                      ? GlassTokens.glow(trigColor, intensity: 0.25)
                      : null,
                ),
                child: Icon(
                  _triggerIcon(rule.triggerType),
                  size: 22,
                  color: rule.enabled ? trigColor : Colors.grey,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: rule.enabled
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
                        Text(
                          _triggerLabel(rule.triggerType),
                          style: TextStyle(
                            color: rule.enabled ? trigColor : Colors.grey,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          ' • ${rule.actions.length} hành động',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.onDarkMuted
                                : AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GlassToggle(
                value: rule.enabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          if (rule.description != null && rule.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              rule.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.onDarkMuted : AppColors.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Visual Pipeline: IF (Trigger/Conditions) -> THEN (Actions)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: trigColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: trigColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'KHI (IF)',
                        style: TextStyle(
                          color: trigColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rule.conditions.isEmpty
                            ? (rule.triggerType == 'SCHEDULE'
                                ? 'Theo lịch trình đã cài đặt'
                                : 'Luôn kích hoạt khi có sự kiện')
                            : rule.conditions
                                .map((c) =>
                                    '${c.deviceName ?? c.attribute} ${c.operatorSymbol} ${c.expectedValue}')
                                .join(' ${rule.conditions.first.logicalOperator} '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.onDark
                              : AppColors.onSurface,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Container(
                    width: 1.5,
                    height: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                  ),
                ),

                // THEN
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mint.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: mint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'THÌ (THEN)',
                        style: TextStyle(
                          color: mint,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rule.actions.isEmpty
                            ? 'Chưa gán hành động'
                            : rule.actions.map(_formatAction).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.onDark
                              : AppColors.onSurface,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Info & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GlassStatusPill(
                    label: _triggerLabel(rule.triggerType),
                    color: trigColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GlassStatusPill(
                    label: rule.enabled ? 'Đang bật' : 'Đã tắt',
                    color: rule.enabled ? mint : Colors.grey,
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Chi tiết',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: accent,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
