import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../home/data/home_providers.dart';
import '../data/security_repository.dart';
import '../domain/security_models.dart';

/// Trung tâm an ninh: sự kiện an ninh + bất thường thiết bị (như web SecurityCenterPage).
class SecurityCenterScreen extends ConsumerStatefulWidget {
  const SecurityCenterScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<SecurityCenterScreen> createState() =>
      _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends ConsumerState<SecurityCenterScreen> {
  late int _tab = widget.initialTab;
  String? _status;
  final Set<String> _busy = {};

  Future<void> _run(
    String id,
    Future<void> Function() action,
    String ok,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(id));
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
      ref.invalidate(anomaliesProvider);
      ref.invalidate(securityEventsProvider);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _resolve(String homeId, DeviceAnomaly anomaly) async {
    final noteController = TextEditingController();
    var falsePositive = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đánh dấu đã xử lý'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: falsePositive,
                onChanged: (value) =>
                    setDialogState(() => falsePositive = value ?? false),
                title: const Text('Báo động giả'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true) return;
    await _run(
      anomaly.id,
      () => ref
          .read(securityRepositoryProvider)
          .resolveAnomaly(
            homeId,
            anomaly.id,
            falsePositive: falsePositive,
            note: note.isEmpty ? null : note,
          ),
      'Đã đánh dấu đã xử lý',
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeId = ref.watch(currentHomeIdProvider);
    final statuses = _tab == 0 ? eventStatusLabels : anomalyStatusLabels;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GlassAppBar(title: 'Trung tâm an ninh', onBack: () => context.pop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              0,
            ),
            child: GlassSegmentedControl(
              selectedIndex: _tab,
              onChanged: (index) => setState(() {
                _tab = index;
                _status = null;
              }),
              segments: const [
                GlassSegment(label: 'Sự kiện', icon: Icons.shield_outlined),
                GlassSegment(
                  label: 'Bất thường',
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.sm,
              ),
              children: [
                for (final entry in {null: 'Tất cả', ...statuses}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GlassFilterChip(
                      label: entry.value,
                      selected: _status == entry.key,
                      onTap: () => setState(() => _status = entry.key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: homeId == null
                ? const _Message('Bạn chưa có nhà nào.')
                : _tab == 0
                ? _buildEvents(homeId)
                : _buildAnomalies(homeId),
          ),
        ],
      ),
    );
  }

  Widget _buildEvents(String homeId) {
    final repo = ref.read(securityRepositoryProvider);
    return _AsyncList<SecurityEvent>(
      value: ref.watch(securityEventsProvider(_status)),
      onRefresh: () => ref.refresh(securityEventsProvider(_status).future),
      empty: 'Không có sự kiện an ninh.',
      itemBuilder: (event) => _IncidentCard(
        icon: event.eventType == 'INTRUSION'
            ? Icons.gpp_maybe_rounded
            : Icons.directions_run_rounded,
        color: _eventColor(event.status),
        title: event.title,
        detail: [
          event.deviceName,
          event.location ?? event.roomName,
        ].whereType<String>().join(' · '),
        time: event.detectedAt,
        statusLabel: eventStatusLabels[event.status] ?? event.status,
        busy: _busy.contains(event.id),
        actions: [
          if (event.status == 'DETECTED') ...[
            _Action(
              'Báo động giả',
              () => _run(
                event.id,
                () => repo.updateEvent(homeId, event.id, 'dismiss'),
                'Đã đánh dấu báo động giả',
              ),
            ),
            _Action(
              'Xác nhận',
              primary: true,
              () => _run(
                event.id,
                () => repo.updateEvent(homeId, event.id, 'confirm'),
                'Đã xác nhận sự kiện an ninh',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalies(String homeId) {
    final repo = ref.read(securityRepositoryProvider);
    return _AsyncList<DeviceAnomaly>(
      value: ref.watch(anomaliesProvider(_status)),
      onRefresh: () => ref.refresh(anomaliesProvider(_status).future),
      empty: 'Không có bất thường nào.',
      itemBuilder: (anomaly) => _IncidentCard(
        icon: switch (anomaly.anomalyType) {
          'SMOKE_DETECTED' ||
          'GAS_LEAKAGE' => Icons.local_fire_department_rounded,
          'HIGH_TEMPERATURE' => Icons.thermostat_rounded,
          _ => Icons.cloud_off_rounded,
        },
        color: _anomalyColor(anomaly.status),
        title: anomaly.title,
        detail: [
          anomaly.deviceName,
          anomaly.roomName,
          if (anomaly.currentValue != null) 'Giá trị: ${anomaly.currentValue}',
          if (anomaly.severity != null)
            'Mức độ: ${severityLabels[anomaly.severity] ?? anomaly.severity}',
          if ((anomaly.occurrenceCount ?? 1) > 1)
            'Lặp lại ${anomaly.occurrenceCount} lần',
        ].whereType<String>().join(' · '),
        reason: anomaly.reason,
        time: anomaly.detectedAt,
        statusLabel: anomalyStatusLabels[anomaly.status] ?? anomaly.status,
        busy: _busy.contains(anomaly.id),
        actions: [
          if (anomaly.status == 'OPEN')
            _Action(
              'Xác nhận',
              () => _run(
                anomaly.id,
                () => repo.acknowledgeAnomaly(homeId, anomaly.id),
                'Đã xác nhận sự cố',
              ),
            ),
          if (anomaly.status != 'RESOLVED' && anomaly.deviceId != null)
            // Ticket tạo từ anomaly sẽ tự đóng anomaly khi thiết bị được sửa xong.
            _Action(
              'Báo hỏng',
              () => context.push(
                Uri(
                  path: '/maintenance/new',
                  queryParameters: {
                    'deviceId': anomaly.deviceId!,
                    'anomalyId': anomaly.id,
                    'note': anomaly.title,
                  },
                ).toString(),
              ),
            ),
          if (anomaly.status != 'RESOLVED')
            _Action('Đã xử lý', primary: true, () => _resolve(homeId, anomaly)),
        ],
      ),
    );
  }

  Color _eventColor(String status) => switch (status) {
    'DETECTED' => AppColors.auroraWarning,
    'CONFIRMED' => AppColors.auroraError,
    _ => Colors.grey,
  };

  Color _anomalyColor(String status) => switch (status) {
    'OPEN' => AppColors.auroraError,
    'ACKNOWLEDGED' => AppColors.auroraWarning,
    _ => AppColors.auroraMint,
  };
}

class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({
    required this.value,
    required this.onRefresh,
    required this.empty,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> value;
  final Future<void> Function() onRefresh;
  final String empty;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message(error.toString()),
      data: (items) => RefreshIndicator(
        onRefresh: onRefresh,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [const SizedBox(height: 120), _Message(empty)],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.navClearance,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => itemBuilder(items[index]),
              ),
      ),
    );
  }
}

class _Action {
  const _Action(this.label, this.onTap, {this.primary = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.time,
    required this.statusLabel,
    required this.actions,
    required this.busy,
    this.reason,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String? reason;
  final DateTime time;
  final String statusLabel;
  final List<_Action> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        radius: AppRadius.card,
        blur: GlassTokens.blurSm,
        padding: const EdgeInsets.all(AppSpacing.md),
        semanticLabel: '$title, $statusLabel',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                      if (reason != null && reason!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          reason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          GlassStatusPill(label: statusLabel, color: color),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            DateFormat('HH:mm • dd/MM').format(time),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                children: [
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    for (final action in actions)
                      action.primary
                          ? FilledButton(
                              onPressed: action.onTap,
                              child: Text(action.label),
                            )
                          : OutlinedButton(
                              onPressed: action.onTap,
                              child: Text(action.label),
                            ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
