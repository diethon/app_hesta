import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/studio.dart';
import '../../../core/widgets/glass/glass_filter_chip.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/state_views.dart';
import '../../recommendation/presentation/recommendations_screen.dart';
import '../../scene/presentation/scenes_screen.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';
import 'automation_rule_detail_screen.dart';
import 'automation_rule_editor_screen.dart';
import '../domain/rule_options.dart' show eventFriendlyNames, formatDuration;
import '../../groups/domain/device_group.dart';
import 'rule_editor_parts.dart' show actionSentence, capitalize, conditionSentence, menuItem, scheduleSentence;

class AutomationRulesScreen extends ConsumerStatefulWidget {
  const AutomationRulesScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  @override
  ConsumerState<AutomationRulesScreen> createState() =>
      _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends ConsumerState<AutomationRulesScreen> {
  String _status = 'all'; // all, enabled, disabled
  String _type = 'all'; // all, SENSOR, EVENT, SCHEDULE
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
  /// `d:id` hoặc `g:id`: quy tắc theo dõi hoặc điều khiển thiết bị / nhóm đó.
  String _target = '';

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<AutomationRule>> rulesAsync,
    bool isDark,
    Color accent,
    Color mint,
  ) {
    final theme = Theme.of(context);
    final allRules = rulesAsync.valueOrNull ?? [];
    final sensorCount = allRules
        .where((r) => r.triggerType.toUpperCase() == 'SENSOR')
        .length;
    final scheduleCount = allRules
        .where((r) => r.triggerType.toUpperCase() == 'SCHEDULE')
        .length;
    final eventCount = allRules
        .where((r) => r.triggerType.toUpperCase() == 'EVENT')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Navigation Banners when NOT embedded
        if (!widget.isEmbedded) ...[
          Row(
            children: [
              Expanded(
                child: StudioCard(
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
                          color: StudioColors.of(context).accentSoft,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: StudioColors.of(context).accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gợi ý thông minh',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Từ thói quen của bạn',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: StudioColors.of(context).muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StudioCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScenesScreen()),
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
                          color: StudioColors.of(context).accentSoft,
                        ),
                        child: Icon(
                          Icons.layers_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Kịch bản',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Điều khiển nhiều thiết bị 1 chạm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: StudioColors.of(context).muted,
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

        // Tìm kiếm + bộ lọc (giống web)
        TextField(
          controller: _search,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Tìm quy tắc, thiết bị, kịch bản…',
            filled: true,
            fillColor: StudioColors.of(context).card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: StudioColors.of(context).border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: StudioColors.of(context).border),
            ),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (key, label) in const [
                ('all', 'Tất cả'),
                ('enabled', 'Đang bật'),
                ('disabled', 'Đang tắt'),
              ]) ...[
                GlassFilterChip(
                  label: '$label (${switch (key) {
                    'enabled' => allRules.where((r) => r.enabled).length,
                    'disabled' => allRules.where((r) => !r.enabled).length,
                    _ => allRules.length,
                  }})',
                  selected: _status == key,
                  onTap: () => setState(() => _status = key),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (key, label) in [
                ('all', 'Mọi loại'),
                ('SENSOR', 'Cảm biến ($sensorCount)'),
                ('EVENT', 'Sự kiện ($eventCount)'),
                ('SCHEDULE', 'Lịch ($scheduleCount)'),
              ]) ...[
                GlassFilterChip(
                  label: label,
                  selected: _type == key,
                  onTap: () => setState(() => _type = key),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _targetFilter(context, rulesAsync.valueOrNull ?? const []),
        const SizedBox(height: AppSpacing.md),

        rulesAsync.when(
          data: (rules) {
            final filtered = rules.where(_matches).toList();
            if (filtered.isEmpty) {
              final isFiltered = _status != 'all' || _type != 'all' || _query.isNotEmpty || _target.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyView(
                        message: isFiltered
                            ? 'Không có quy tắc nào khớp bộ lọc này.'
                            : 'Chưa có quy tắc nào.\nTạo quy tắc để nhà tự bật/tắt thiết bị theo giờ hoặc cảm biến.',
                        icon: Icons.alt_route_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (isFiltered)
                        TextButton(
                          onPressed: () => setState(() {
                            _status = 'all';
                            _type = 'all';
                            _target = '';
                            _query = '';
                            _search.clear();
                          }),
                          child: const Text('Xoá bộ lọc'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openEditor(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tạo quy tắc'),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            const groups = [
              ('SENSOR', 'Cảm biến', 'Chạy khi giá trị cảm biến khớp điều kiện'),
              ('EVENT', 'Sự kiện', 'Chạy khi thiết bị báo một sự kiện'),
              ('SCHEDULE', 'Lịch giờ', 'Chạy vào giờ đã hẹn'),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (type, title, hint) in groups)
                  if (filtered.any((r) => r.triggerType.toUpperCase() == type)) ...[
                    _GroupHeader(
                      title: title,
                      hint: hint,
                      count: filtered.where((r) => r.triggerType.toUpperCase() == type).length,
                    ),
                    for (final rule in filtered.where((r) => r.triggerType.toUpperCase() == type))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _RuleListItem(
                          rule: rule,
                          onTap: () => _openDetail(context, rule),
                          onToggle: () {
                            HapticFeedback.selectionClick();
                            ref.read(automationRulesListProvider.notifier).toggleRule(rule.id);
                          },
                          menu: (ctx) => [
                            menuItem(ctx, Icons.edit_outlined, 'Chỉnh sửa', () => _openEditor(context, rule: rule)),
                            menuItem(ctx, Icons.history_rounded, 'Xem lịch sử',
                                () => _openEditor(context, rule: rule, history: true)),
                            if (rule.triggerType.toUpperCase() == 'SCHEDULE')
                              menuItem(ctx, Icons.alarm_rounded, 'Lịch chạy', () => _openEditor(context, rule: rule)),
                            menuItem(ctx, Icons.copy_rounded, 'Nhân bản', () => _duplicate(context, rule)),
                            menuItem(ctx, Icons.delete_outline_rounded, 'Xoá quy tắc', () => _delete(context, rule),
                                danger: true),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            );
          },
          loading: () => const GlassListSkeleton(itemCount: 3, itemHeight: 160),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 30),
            child: ErrorView(
              message: 'Không tải được quy tắc. Kiểm tra kết nối rồi thử lại.',
              onRetry: () => ref.read(automationRulesListProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _targetFilter(BuildContext context, List<AutomationRule> rules) {
    final c = StudioColors.of(context);
    final groups = ref.watch(automationGroupsProvider).valueOrNull ?? const <DeviceGroup>[];
    // Thiết bị lấy từ chính các quy tắc: chỉ những thiết bị có quy tắc dùng tới.
    final devices = <String, String>{
      for (final r in rules) ...{
        for (final c in r.conditions)
          if (c.deviceId != null) c.deviceId!: c.deviceName ?? 'Thiết bị',
        for (final a in r.actions)
          if (a.deviceId != null) a.deviceId!: a.deviceName ?? 'Thiết bị',
      },
    };
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('Mọi thiết bị và nhóm')),
      for (final g in groups) DropdownMenuItem(value: 'g:${g.id}', child: Text('Nhóm · ${g.name}')),
      for (final e in devices.entries) DropdownMenuItem(value: 'd:${e.key}', child: Text(e.value)),
    ];
    return DropdownButtonFormField<String>(
      // Thiết bị / nhóm đã bị xoá: quay về "tất cả".
      initialValue: items.any((i) => i.value == _target) ? _target : '',
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.filter_alt_outlined, color: c.muted, size: 20),
        filled: true,
        fillColor: c.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
      ),
      items: items,
      onChanged: (v) => setState(() => _target = v ?? ''),
    );
  }

  bool _matches(AutomationRule r) {
    if (_status == 'enabled' && !r.enabled) return false;
    if (_status == 'disabled' && r.enabled) return false;
    if (_type != 'all' && r.triggerType.toUpperCase() != _type) return false;
    if (_target.isNotEmpty && !ruleTouches(r, _target, ref.read(automationGroupsProvider).valueOrNull ?? const [])) {
      return false;
    }
    if (_query.isEmpty) return true;
    final hay = [
      r.name,
      r.description ?? '',
      for (final c in r.conditions) ...[c.deviceName ?? '', c.groupName ?? ''],
      for (final a in r.actions) ...[a.deviceName ?? '', a.sceneName ?? '', a.groupName ?? ''],
    ].join(' ').toLowerCase();
    return hay.contains(_query);
  }

  Future<void> _openEditor(BuildContext context, {AutomationRule? rule, bool history = false}) async {
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => AutomationRuleEditorScreen(rule: rule, openHistory: history),
      ),
    );
    if (mounted) unawaited(ref.read(automationRulesListProvider.notifier).refresh());
  }

  Future<void> _openDetail(BuildContext context, AutomationRule rule) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => AutomationRuleDetailScreen(rule: rule)),
    );
    if (mounted) unawaited(ref.read(automationRulesListProvider.notifier).refresh());
  }

  Future<void> _duplicate(BuildContext context, AutomationRule rule) async {
    try {
      await ref.read(automationRulesListProvider.notifier).duplicateRule(rule);
      if (context.mounted) showStudioSnack(context, 'Đã tạo bản sao (đang tắt)');
    } catch (_) {
      if (context.mounted) showStudioSnack(context, 'Không nhân bản được quy tắc', success: false);
    }
  }

  Future<void> _delete(BuildContext context, AutomationRule rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá quy tắc?'),
        content: Text('"${rule.name}" sẽ ngừng chạy và bị xoá vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: StudioColors.of(ctx).danger),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(automationRulesListProvider.notifier).deleteRule(rule.id);
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(automationRulesListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = StudioColors.of(context).accent;
    final mint = StudioColors.of(context).on;

    if (widget.isEmbedded) {
      return _buildContent(context, rulesAsync, isDark, accent, mint);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Tạo quy tắc',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
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
                    onTap: () => ref
                        .read(automationRulesListProvider.notifier)
                        .refresh(),
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.hint, required this.count});

  final String title;
  final String hint;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title ($count)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
          Text(hint, style: TextStyle(fontSize: 12.5, color: c.faint)),
        ],
      ),
    );
  }
}

class _RuleListItem extends StatelessWidget {
  const _RuleListItem({
    required this.rule,
    required this.onTap,
    required this.onToggle,
    required this.menu,
  });

  final AutomationRule rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final List<PopupMenuEntry<VoidCallback>> Function(BuildContext) menu;

  static IconData triggerIcon(String type) => switch (type.toUpperCase()) {
    'SCHEDULE' => Icons.schedule_rounded,
    'EVENT' => Icons.bolt_rounded,
    _ => Icons.sensors_rounded,
  };

  String get _when {
    final type = rule.triggerType.toUpperCase();
    if (type == 'SCHEDULE') return scheduleSentence(rule.schedules);
    if (type == 'EVENT') {
      final c = rule.conditions.firstOrNull;
      final ev = eventFriendlyNames['${c?.expectedValue}'] ?? 'thiết bị báo có sự kiện';
      return capitalize('$ev${c?.deviceName != null ? ' từ ${c!.deviceName}' : ''}');
    }
    if (rule.conditions.isEmpty) return 'Chưa có điều kiện';
    final ops = rule.conditions.skip(1).map((c) => c.logicalOperator.toUpperCase());
    final join = ops.contains('OR') ? ' hoặc ' : ' và ';
    final hold = rule.holdSeconds > 0 ? ', liên tục ${formatDuration(rule.holdSeconds)}' : '';
    // Shown after a "Khi" label, so no "Khi" here.
    return capitalize('${rule.conditions.map((c) => conditionSentence(c, null)).join(join)}$hold');
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final on = rule.enabled;
    final actions = [...rule.actions]..sort((a, b) => a.order.compareTo(b.order));
    final noActions = actions.isEmpty;
    final condCount = rule.conditions.length;

    return StudioCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudioIconTile(icon: triggerIcon(rule.triggerType), active: on),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: on ? c.text : c.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Trigger type is already shown by the icon and the group header.
                      [
                        on ? 'Đang bật' : 'Đang tắt',
                        if (rule.triggerType.toUpperCase() == 'SENSOR') '$condCount điều kiện',
                      ].join(' · '),
                      style: TextStyle(fontSize: 12.5, color: c.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: noActions ? 'Thêm hành động trước khi bật' : '',
                child: GlassToggle(value: on, onChanged: noActions && !on ? null : (_) => onToggle()),
              ),
              PopupMenuButton<VoidCallback>(
                tooltip: 'Tuỳ chọn',
                icon: Icon(Icons.more_vert_rounded, color: c.muted),
                onSelected: (fn) => fn(),
                itemBuilder: menu,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.soft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                _FlowLine(icon: triggerIcon(rule.triggerType), label: 'Khi', text: _when),
                const SizedBox(height: 8),
                _FlowLine(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Thì',
                  text: noActions
                      ? 'Chưa có hành động'
                      : [
                          for (final a in actions.take(3)) actionSentence(a, null, null),
                          if (actions.length > 3) '+${actions.length - 3} hành động khác',
                        ].join('\n'),
                ),
              ],
            ),
          ),
          if (noActions) ...[
            const SizedBox(height: 10),
            StudioTag(label: 'Thiếu hành động', color: c.warn, icon: Icons.warning_amber_rounded),
          ],
        ],
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  const _FlowLine({required this.icon, required this.label, required this.text});

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: c.accent),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(label, style: TextStyle(fontSize: 12.5, color: c.muted)),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// Quy tắc có theo dõi / điều khiển thiết bị hoặc nhóm [target] (`d:id` / `g:id`) không.
/// Thiết bị tính cả qua nhóm chứa nó, nhóm tính cả qua thiết bị trong nhóm (giống web).
bool ruleTouches(AutomationRule rule, String target, List<DeviceGroup> groups) {
  final id = target.substring(2);
  final refs = [
    for (final c in rule.conditions) (c.deviceId, c.groupId),
    for (final a in rule.actions) (a.deviceId, a.groupId),
  ];
  if (target.startsWith('g:')) {
    final members = groups.where((g) => g.id == id).firstOrNull?.deviceIds ?? const [];
    return refs.any((r) => r.$2 == id || (r.$1 != null && members.contains(r.$1)));
  }
  final groupsOfDevice = {for (final g in groups) if (g.deviceIds.contains(id)) g.id};
  return refs.any((r) => r.$1 == id || (r.$2 != null && groupsOfDevice.contains(r.$2)));
}
