import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/studio.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';
import 'automation_rule_editor_screen.dart';
import '../domain/rule_options.dart' show formatDuration, kDelayAction;
import 'rule_editor_parts.dart'
    show actionSentence, capitalize, conditionSentence, scheduleSentence;

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

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
  }

  Future<void> _deleteRule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá quy tắc?'),
        content: Text('"${_rule.name}" sẽ ngừng chạy và bị xoá vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
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
      await ref.read(automationRulesListProvider.notifier).deleteRule(_rule.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final executionsAsync = ref.watch(
      automationRuleExecutionsProvider(_rule.id),
    );
    final join =
        _rule.conditions.isNotEmpty &&
            _rule.conditions.first.logicalOperator.toUpperCase() == 'OR'
        ? 'hoặc'
        : 'và';

    return StudioBackground(
      child: Builder(
        builder: (context) {
          final c = StudioColors.of(context);
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
                    title: 'Chi tiết quy tắc',
                    onBack: () => Navigator.of(context).maybePop(),
                    actions: [
                      GlassIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Sửa quy tắc',
                        onTap: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AutomationRuleEditorScreen(rule: _rule),
                                ),
                              );
                          if (updated == true && context.mounted) {
                            await ref
                                .read(automationRulesListProvider.notifier)
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
                      StudioCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StudioTag(
                                  label: describeTrigger(_rule.triggerType),
                                  color: c.accent,
                                ),
                                const Spacer(),
                                Text(
                                  _rule.enabled ? 'Đang bật' : 'Đã tắt',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.muted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GlassToggle(
                                  value: _rule.enabled,
                                  onChanged: (_) async {
                                    await ref
                                        .read(
                                          automationRulesListProvider.notifier,
                                        )
                                        .toggleRule(_rule.id);
                                    setState(() {
                                      _rule = _rule.copyWith(
                                        enabled: !_rule.enabled,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _rule.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: c.text,
                              ),
                            ),
                            if (_rule.description != null &&
                                _rule.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                _rule.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: c.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _SectionTitle('Khi nào chạy'),
                      StudioCard(
                        child: _rule.conditions.isEmpty
                            ? _Line(
                                icon: Icons.schedule_rounded,
                                text:
                                    _rule.triggerType.toUpperCase() ==
                                        'SCHEDULE'
                                    ? scheduleSentence(_rule.schedules)
                                    : 'Mỗi khi có sự kiện xảy ra',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final (i, cond)
                                      in _rule.conditions.indexed) ...[
                                    if (i > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 28,
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          join,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.faint,
                                          ),
                                        ),
                                      ),
                                    _Line(
                                      icon: Icons.sensors_rounded,
                                      text: capitalize(
                                        conditionSentence(cond, null),
                                      ),
                                    ),
                                  ],
                                  if (_rule.holdSeconds > 0)
                                    _Line(
                                      icon: Icons.timer_outlined,
                                      text:
                                          'Chỉ chạy khi đúng liên tục ${formatDuration(_rule.holdSeconds)}',
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      _SectionTitle('Sẽ làm gì'),
                      StudioCard(
                        child: _rule.actions.isEmpty
                            ? Text(
                                'Chưa có hành động.',
                                style: TextStyle(color: c.faint),
                              )
                            : Column(
                                children: [
                                  for (final a in _rule.actions)
                                    _Line(
                                      icon: a.action == kDelayAction
                                          ? Icons.hourglass_bottom_rounded
                                          : a.groupId != null
                                          ? Icons.grid_view_rounded
                                          : a.sceneName != null &&
                                                a.deviceName == null
                                          ? Icons.layers_outlined
                                          : Icons.arrow_forward_rounded,
                                      text: actionSentence(a, null, null),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      _SectionTitle('Lần chạy gần đây'),
                      executionsAsync.when(
                        data: (logs) => StudioCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: logs.every((l) => l.isTest)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Quy tắc này chưa chạy lần nào.',
                                      style: TextStyle(color: c.faint),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final log in logs.where(
                                      (l) => !l.isTest,
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              log.status.toUpperCase() ==
                                                      'SUCCESS'
                                                  ? Icons.check_circle_rounded
                                                  : Icons.error_rounded,
                                              size: 18,
                                              color:
                                                  log.status.toUpperCase() ==
                                                      'SUCCESS'
                                                  ? c.on
                                                  : c.danger,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                log.details ??
                                                    (log.status.toUpperCase() ==
                                                            'SUCCESS'
                                                        ? 'Chạy thành công'
                                                        : 'Chạy không thành công'),
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  color: c.text,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              describeWhen(log.executedAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: c.faint,
                                              ),
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
                            'Xoá quy tắc',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _deleteRule,
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

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
