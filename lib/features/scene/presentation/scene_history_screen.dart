import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_status_pill.dart';
import '../../../core/widgets/state_views.dart';
import '../data/scene_providers.dart';
import '../domain/scene.dart';

class SceneHistoryScreen extends ConsumerWidget {
  const SceneHistoryScreen({required this.scene, super.key});

  final Scene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sceneExecutionsProvider(scene.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                title: 'Lịch sử chạy: ${scene.name}',
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.navClearance,
              ),
              sliver: historyAsync.when(
                data: (executions) {
                  if (executions.isEmpty) {
                    return const SliverFillRemaining(
                      child: EmptyView(
                        message: 'Chưa có lịch sử thực thi nào cho kịch bản này.',
                        icon: Icons.history_rounded,
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = executions[index];
                        final formattedDate = DateFormat(
                          'HH:mm:ss • dd/MM/yyyy',
                        ).format(item.startedAt);

                        final isSuccess = item.status == 'SUCCESS';
                        final statusColor = isSuccess
                            ? (isDark
                                ? AppColors.auroraMint
                                : AppColors.auroraMintOnLight)
                            : AppColors.error;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: GlassCard(
                            radius: AppRadius.card,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    GlassStatusPill(
                                      label: item.status,
                                      color: statusColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Nguồn kích hoạt: ${item.triggerSource}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.onDarkMuted
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                if (item.resultDetail.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  const Divider(height: 1, color: Colors.white10),
                                  const SizedBox(height: AppSpacing.sm),
                                  ...item.resultDetail.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            d.success
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            size: 16,
                                            color: d.success
                                                ? (isDark
                                                    ? AppColors.auroraMint
                                                    : AppColors.auroraMintOnLight)
                                                : AppColors.error,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${d.deviceId} ➔ ${d.action}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: executions.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: ErrorView(
                    message: 'Không thể tải lịch sử: $e',
                    onRetry: () {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
