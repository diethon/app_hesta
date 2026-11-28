import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../data/maintenance_repository.dart';
import 'maintenance_status.dart';

class MaintenanceListScreen extends ConsumerWidget {
  const MaintenanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tickets = ref.watch(maintenanceTicketsProvider);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/maintenance/new'),
        icon: const Icon(Icons.build_rounded),
        label: const Text('Báo hỏng'),
      ),
      body: Column(
        children: [
          GlassAppBar(title: 'Bảo trì thiết bị', onBack: () => context.pop()),
          Expanded(
            child: tickets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(maintenanceTicketsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.lg,
                    AppSpacing.screen,
                    AppSpacing.navClearance,
                  ),
                  children: [
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 120),
                        child: Text(
                          'Chưa có yêu cầu bảo trì nào.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                    for (final ticket in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          radius: AppRadius.card,
                          blur: GlassTokens.blurSm,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          semanticLabel: ticket.title,
                          onTap: () =>
                              context.push('/maintenance/${ticket.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket.title,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  MaintenanceStatusPill(ticket.status),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                [
                                  ticket.code,
                                  ticket.deviceNames.join(', '),
                                ].where((s) => s.isNotEmpty).join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                              if (ticket.scheduledStart != null)
                                Text(
                                  'Lịch hẹn: ${DateFormat('HH:mm dd/MM').format(ticket.scheduledStart!)}'
                                  '${ticket.scheduleConfirmed ? ' (đã xác nhận)' : ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
