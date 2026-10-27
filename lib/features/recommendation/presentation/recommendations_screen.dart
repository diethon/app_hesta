import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_filter_chip.dart';
import '../../../core/widgets/state_views.dart';
import '../data/recommendation_providers.dart';
import 'widgets/ml_model_status_card.dart';
import 'widgets/recommendation_item_card.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  String _selectedTab = 'pending'; // pending, history
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    final count =
        await ref.read(recommendationsListProvider.notifier).generate();

    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Mô hình ML đã phát hiện và tạo $count đề xuất mới!'
                : 'Không có hành vi nào đạt ngưỡng tin cậy >= 80% lúc này.',
          ),
          backgroundColor: count > 0 ? mint : AppColors.auroraWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recsAsync = ref.watch(recommendationsListProvider);
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
                title: 'Đề xuất AI (Recommendations)',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Làm mới',
                    onTap: () {
                      ref
                          .read(recommendationsListProvider.notifier)
                          .refresh();
                      ref.read(mlModelStatusProvider.notifier).refresh();
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
                  // ML Model Status
                  const MlModelStatusCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // Generate AI Button
                  GlassCard(
                    onTap: _isGenerating ? null : _generate,
                    radius: AppRadius.card,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    fill: (isDark ? AppColors.orbViolet : Colors.purple)
                        .withValues(alpha: 0.15),
                    shadows: GlassTokens.glow(
                      isDark ? AppColors.orbViolet : Colors.purple,
                      intensity: 0.3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isGenerating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: isDark ? AppColors.orbViolet : Colors.purple,
                          ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _isGenerating
                              ? 'Đang phân tích dữ liệu 30 ngày qua...'
                              : 'Phân tích hành vi & Tạo đề xuất mới',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.onDark : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tabs: Pending vs History
                  Row(
                    children: [
                      GlassFilterChip(
                        label: 'Chờ duyệt',
                        selected: _selectedTab == 'pending',
                        onTap: () =>
                            setState(() => _selectedTab = 'pending'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GlassFilterChip(
                        label: 'Lịch sử giải quyết',
                        selected: _selectedTab == 'history',
                        onTap: () =>
                            setState(() => _selectedTab = 'history'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Recommendations List
                  recsAsync.when(
                    data: (items) {
                      final filtered = items.where((r) {
                        if (_selectedTab == 'pending') return r.isPending;
                        return !r.isPending;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyView(
                            message: _selectedTab == 'pending'
                                ? 'Hiện không có đề xuất nào đang chờ duyệt.\nNhấn nút phân tích ở trên để tìm thói quen mới!'
                                : 'Chưa có lịch sử đề xuất nào được xử lý.',
                            icon: Icons.psychology_rounded,
                          ),
                        );
                      }

                      return Column(
                        children: filtered
                            .map((rec) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: RecommendationItemCard(
                                    recommendation: rec,
                                    onApprove: () => ref
                                        .read(
                                          recommendationsListProvider.notifier,
                                        )
                                        .approve(rec.id),
                                    onReject: () => ref
                                        .read(
                                          recommendationsListProvider.notifier,
                                        )
                                        .reject(rec.id),
                                    onDismiss: () => ref
                                        .read(
                                          recommendationsListProvider.notifier,
                                        )
                                        .dismiss(rec.id),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: ErrorView(
                        message: 'Không thể tải đề xuất: $e',
                        onRetry: () => ref
                            .read(recommendationsListProvider.notifier)
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
