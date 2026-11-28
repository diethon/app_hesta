import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../home/data/home_providers.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_ticket.dart';
import 'maintenance_slot_editor.dart';
import 'maintenance_status.dart';

final _time = DateFormat('HH:mm dd/MM/yyyy');
final _money = NumberFormat.decimalPattern('vi');

class MaintenanceDetailScreen extends ConsumerStatefulWidget {
  const MaintenanceDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState
    extends ConsumerState<MaintenanceDetailScreen> {
  bool _busy = false;

  MaintenanceRepository get _repo => ref.read(maintenanceRepositoryProvider);

  Future<void> _run(
    Future<MaintenanceTicket> Function(String homeId) action,
    String ok,
  ) async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action(homeId);
      messenger.showSnackBar(SnackBar(content: Text(ok)));
      ref.invalidate(maintenanceTicketProvider(widget.ticketId));
      ref.invalidate(maintenanceTicketsProvider);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Hỏi ghi chú tuỳ chọn; trả null nếu người dùng huỷ.
  Future<String?> _askNote(String title, String confirm) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do (không bắt buộc)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    return ok == true ? text : null;
  }

  Future<void> _reschedule(MaintenanceTicket ticket) async {
    var slots = [defaultSlot()];
    final note = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Đề xuất khung giờ khác',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SlotListEditor(
                slots: slots,
                onChanged: (next) => setSheetState(() => slots = next),
              ),
              TextField(
                controller: note,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              FilledButton(
                onPressed: () {
                  final problem = slotProblem(slots);
                  if (problem != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(problem)));
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Gửi khung giờ mới'),
              ),
            ],
          ),
        ),
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (ok != true) return;
    await _run(
      (homeId) => _repo.reschedule(
        homeId,
        ticket.id,
        slots,
        text.isEmpty ? null : text,
      ),
      'Đã gửi khung giờ mới',
    );
  }

  Future<void> _rate(MaintenanceTicket ticket) async {
    var rating = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đánh giá dịch vụ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: '$star sao',
                      onPressed: () => setDialogState(() => rating = star),
                      icon: Icon(
                        star <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: comment,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Nhận xét'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
    final text = comment.text.trim();
    comment.dispose();
    if (ok != true) return;
    await _run(
      (homeId) =>
          _repo.feedback(homeId, ticket.id, rating, text.isEmpty ? null : text),
      'Cảm ơn bạn đã đánh giá',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(maintenanceTicketProvider(widget.ticketId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GlassAppBar(
            title: ticket.valueOrNull?.code ?? 'Yêu cầu bảo trì',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ticket.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (t) => RefreshIndicator(
                onRefresh: () => ref.refresh(
                  maintenanceTicketProvider(widget.ticketId).future,
                ),
                child: _buildBody(context, t),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceTicket t) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    Widget card(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassContainer(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );

    final quote = t.quote;
    final actions = <Widget>[
      if (t.canConfirmSchedule)
        FilledButton(
          onPressed: () => _run(
            (h) => _repo.confirmSchedule(h, t.id),
            'Đã xác nhận lịch hẹn',
          ),
          child: const Text('Xác nhận lịch hẹn'),
        ),
      if (t.canReschedule)
        OutlinedButton(
          onPressed: () => _reschedule(t),
          child: const Text('Đổi lịch'),
        ),
      if (t.canDecideQuote) ...[
        FilledButton(
          onPressed: () =>
              _run((h) => _repo.approveQuote(h, t.id), 'Đã duyệt báo giá'),
          child: const Text('Duyệt báo giá'),
        ),
        OutlinedButton(
          onPressed: () async {
            final note = await _askNote('Từ chối báo giá', 'Từ chối');
            if (note == null) return;
            await _run(
              (h) => _repo.rejectQuote(h, t.id, note.isEmpty ? null : note),
              'Đã từ chối báo giá',
            );
          },
          child: const Text('Từ chối báo giá'),
        ),
      ],
      if (t.canRate)
        FilledButton(onPressed: () => _rate(t), child: const Text('Đánh giá')),
      if (t.canCancel)
        TextButton(
          onPressed: () async {
            final note = await _askNote('Huỷ yêu cầu bảo trì', 'Huỷ yêu cầu');
            if (note == null) return;
            await _run(
              (h) => _repo.cancel(h, t.id, note.isEmpty ? null : note),
              'Đã huỷ yêu cầu bảo trì',
            );
          },
          child: const Text('Huỷ yêu cầu'),
        ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.navClearance,
      ),
      children: [
        card(t.title, [
          Row(
            children: [
              MaintenanceStatusPill(t.status),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Ưu tiên: ${maintenancePriorityLabels[t.priority] ?? t.priority}',
                style: muted,
              ),
            ],
          ),
          if (t.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(t.description!),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tạo lúc ${_time.format(t.createdAt)}'
            '${t.createdByName != null ? ' bởi ${t.createdByName}' : ''}',
            style: muted,
          ),
          if (t.adminNote?.isNotEmpty ?? false)
            Text('Ghi chú từ HESTA: ${t.adminNote}', style: muted),
          if (t.cancelReason?.isNotEmpty ?? false)
            Text('Lý do huỷ: ${t.cancelReason}', style: muted),
        ]),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: LinearProgressIndicator(),
          )
        else if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ),
        card('Lịch hẹn', [
          if (t.scheduledStart != null && t.scheduledEnd != null)
            Text(
              '${_time.format(t.scheduledStart!)} - '
              '${DateFormat('HH:mm').format(t.scheduledEnd!)}'
              '${t.scheduleConfirmed ? ' (đã xác nhận)' : ''}',
            )
          else
            Text('Chưa có lịch hẹn. Khung giờ bạn rảnh:', style: muted),
          if (t.scheduledStart == null)
            for (final slot in t.slots)
              Text(
                '• ${_time.format(slot.startAt)} - '
                '${DateFormat('HH:mm').format(slot.endAt)}',
              ),
        ]),
        card('Thiết bị', [
          for (final d in t.devices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.devices_other_rounded),
              title: Text(d.deviceName),
              subtitle: Text(
                [
                  d.roomName,
                  d.issueNote,
                  if (d.outcome != null)
                    'Kết quả: ${maintenanceOutcomeLabels[d.outcome] ?? d.outcome}',
                  d.outcomeNote,
                ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
              ),
            ),
        ]),
        if (quote != null)
          card('Báo giá', [
            if (quote.findings?.isNotEmpty ?? false) Text(quote.findings!),
            for (final item in quote.items)
              Row(
                children: [
                  Expanded(
                    child: Text('${item.description} × ${item.quantity}'),
                  ),
                  Text(_money.format(item.amount ?? 0)),
                ],
              ),
            const Divider(),
            Row(
              children: [
                const Expanded(child: Text('Tổng cộng')),
                Text(
                  '${_money.format(quote.total ?? 0)} ${quote.currency ?? 'VND'}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            if (quote.warrantyMonths != null)
              Text('Bảo hành ${quote.warrantyMonths} tháng', style: muted),
          ]),
        if (t.rating != null)
          card('Đánh giá của bạn', [
            Text('★' * t.rating! + '☆' * (5 - t.rating!)),
            if (t.feedback?.isNotEmpty ?? false) Text(t.feedback!),
          ]),
        if (t.events.isNotEmpty)
          card('Lịch sử', [
            for (final e in t.events.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '${_time.format(e.createdAt)} · '
                  '${maintenanceStatusLabels[e.toStatus] ?? e.toStatus ?? ''}'
                  '${e.actorName != null ? ' · ${e.actorName}' : ''}'
                  '${e.note?.isNotEmpty ?? false ? '\n${e.note}' : ''}',
                  style: muted,
                ),
              ),
          ]),
      ],
    );
  }
}
