import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_status_pill.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../home/data/home_providers.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';
import 'automation_rule_editor_screen.dart';

class AutomationRuleDetailScreen extends ConsumerStatefulWidget {
  const AutomationRuleDetailScreen({required this.rule, super.key});

  final AutomationRule rule;

  @override
  ConsumerState<AutomationRuleDetailScreen> createState() =>
      _AutomationRuleDetailScreenState();
}

class _AutomationRuleDetailScreenState
    extends ConsumerState<AutomationRuleDetailScreen> {
  late AutomationRule _rule;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
  }

  Future<void> _testRule() async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return;

    setState(() => _isTesting = true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    try {
      final repo = ref.read(automationRepositoryProvider);
      final result = await repo.testRule(homeId, _rule.id);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor:
                isDark ? AppColors.auroraCanvasMid : AppColors.surface,
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Kết quả chạy thử'),
              ],
            ),
            content: Text(
              result.containsKey('message')
                  ? result['message'].toString()
                  : 'Quy tắc đã được chạy thử thành công!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chạy thử thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _deleteRule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa quy tắc "${_rule.name}"?'),
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
      await ref.read(automationRulesListProvider.notifier).deleteRule(_rule.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final executionsAsync =
        ref.watch(automationRuleExecutionsProvider(_rule.id));

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
                title: 'Chi tiết quy tắc',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Sửa quy tắc',
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              AutomationRuleEditorScreen(rule: _rule),
                        ),
                      );
                      if (updated == true && mounted) {
                        ref
                            .read(automationRulesListProvider.notifier)
                            .refresh();
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
                  // Hero Header Card
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    radius: AppRadius.hero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GlassStatusPill(
                              label: _rule.triggerType,
                              color: accent,
                            ),
                            GlassToggle(
                              value: _rule.enabled,
                              onChanged: (_) async {
                                await ref
                                    .read(automationRulesListProvider.notifier)
                                    .toggleRule(_rule.id);
                                setState(() {
                                  _rule =
                                      _rule.copyWith(enabled: !_rule.enabled);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _rule.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_rule.description != null &&
                            _rule.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _rule.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.onDarkMuted
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Chạy thử quy tắc (Test Rule)',
                          icon: Icons.play_arrow_rounded,
                          isLoading: _isTesting,
                          onPressed: _testRule,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // IF Conditions
                  Text(
                    'ĐIỀU KIỆN KÍCH HOẠT (IF)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    radius: AppRadius.card,
                    child: _rule.conditions.isEmpty
                        ? const Text('Luôn thỏa mãn')
                        : Column(
                            children: _rule.conditions
                                .map((c) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'IF',
                                              style: TextStyle(
                                                color: accent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Text(
                                              '${c.deviceName ?? c.attribute} ${c.operatorSymbol} ${c.expectedValue}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // THEN Actions
                  Text(
                    'HÀNH ĐỘNG THỰC THI (THEN)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mint,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    radius: AppRadius.card,
                    child: _rule.actions.isEmpty
                        ? const Text('Chưa có hành động')
                        : Column(
                            children: _rule.actions
                                .map((a) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: mint.withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'THEN',
                                              style: TextStyle(
                                                color: mint,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Text(
                                              '${a.deviceName ?? a.sceneName ?? "Hành động"}: ${a.action}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Execution History Logs
                  Text(
                    'NHẬT KÝ THỰC THI GẦN ĐÂY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  executionsAsync.when(
                    data: (logs) => GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      radius: AppRadius.card,
                      child: logs.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Chưa có lịch sử thực thi nào.',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.onDarkFaint
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: logs
                                  .map((log) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  DateFormat(
                                                    'HH:mm:ss • dd/MM',
                                                  ).format(log.executedAt),
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (log.details != null)
                                                  Text(
                                                    log.details!,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: isDark
                                                          ? AppColors.onDarkMuted
                                                          : Colors.grey.shade600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            GlassStatusPill(
                                              label: log.status,
                                              color: log.status == 'SUCCESS'
                                                  ? mint
                                                  : AppColors.error,
                                            ),
                                          ],
                                        ),
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

                  // Delete Rule
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      label: const Text(
                        'Xóa quy tắc này',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onPressed: _deleteRule,
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
