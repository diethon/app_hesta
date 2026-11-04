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
import '../../../core/widgets/state_views.dart';
import '../data/recommendation_providers.dart';
import '../domain/recommendation_models.dart';
import 'widgets/ml_model_status_card.dart';
import 'widgets/recommendation_item_card.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  String _selectedTab = 'pending'; // pending, approved, rejected, all_history
  bool _isGenerating = false;

  Future<void> _generate() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _isGenerating = true);

    final count =
        await ref.read(recommendationsListProvider.notifier).generate();

    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                count > 0 ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  count > 0
                      ? 'BehaviorML đã phát hiện và tạo $count đề xuất mới!'
                      : 'Chưa có thói quen lặp lại nào đạt ngưỡng tin cậy >= 80% lúc này.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: count > 0 ? mint : AppColors.auroraWarning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<Recommendation>> recsAsync,
    bool isDark,
    Color mint,
    Color accent,
  ) {
    final theme = Theme.of(context);
    final allItems = recsAsync.valueOrNull ?? [];
    final pendingCount = allItems.where((r) => r.isPending).length;
    final approvedCount =
        allItems.where((r) => r.status.toUpperCase() == 'APPROVED').length;
    final rejectedCount =
        allItems.where((r) => r.status.toUpperCase() == 'REJECTED').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ML Neural Model Status Card
        const MlModelStatusCard(),
        const SizedBox(height: AppSpacing.md),

        // Generate AI Recommendations Tactile Button
        GlassCard(
          onTap: _isGenerating ? null : _generate,
          radius: AppRadius.card,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          fill: (isDark ? AppColors.orbViolet : Colors.purple)
              .withValues(alpha: 0.16),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isDark ? AppColors.orbViolet : Colors.purple)
                  .withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
          shadows: GlassTokens.glow(
            isDark ? AppColors.orbViolet : Colors.purple,
            intensity: 0.28,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGenerating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? AppColors.orbViolet : Colors.purple)
                        .withValues(alpha: 0.25),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: isDark ? AppColors.orbViolet : Colors.purple,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isGenerating
                          ? 'Đang phân tích dữ liệu 30 ngày qua...'
                          : 'Phân tích hành vi & Quét đề xuất mới',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.onDark : AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!_isGenerating)
                      Text(
                        'Quét chu kỳ bật/tắt thiết bị để tối ưu hóa điện năng và sinh hoạt',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.onDarkMuted
                              : AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Sub-filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GlassFilterChip(
                label: 'Chờ duyệt ($pendingCount)',
                selected: _selectedTab == 'pending',
                onTap: () => setState(() => _selectedTab = 'pending'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đã duyệt ($approvedCount)',
                selected: _selectedTab == 'approved',
                onTap: () => setState(() => _selectedTab = 'approved'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đã từ chối ($rejectedCount)',
                selected: _selectedTab == 'rejected',
                onTap: () => setState(() => _selectedTab = 'rejected'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Tất cả lịch sử',
                selected: _selectedTab == 'all_history',
                onTap: () => setState(() => _selectedTab = 'all_history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Recommendations List
        recsAsync.when(
          data: (items) {
            final filtered = items.where((r) {
              if (_selectedTab == 'pending') return r.isPending;
              if (_selectedTab == 'approved') {
                return r.status.toUpperCase() == 'APPROVED';
              }
              if (_selectedTab == 'rejected') {
                return r.status.toUpperCase() == 'REJECTED';
              }
              return !r.isPending; // all_history
            }).toList();

            if (filtered.isEmpty) {
              String emptyMsg =
                  'Hiện không có đề xuất nào đang chờ duyệt.\nNhấn nút phân tích ở trên để tìm thói quen mới!';
              if (_selectedTab == 'approved') {
                emptyMsg = 'Chưa có đề xuất nào được chấp thuận.';
              } else if (_selectedTab == 'rejected') {
                emptyMsg = 'Chưa có đề xuất nào bị từ chối.';
              } else if (_selectedTab == 'all_history') {
                emptyMsg = 'Lịch sử giải quyết đề xuất đang trống.';
              }

              return Padding(
                padding: const EdgeInsets.only(top: 36, bottom: 44),
                child: EmptyView(
                  message: emptyMsg,
                  icon: Icons.psychology_rounded,
                ),
              );
            }

            return Column(
              children: filtered
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RecommendationItemCard(
                        recommendation: rec,
                        onApprove: () async {
                          final success = await ref
                              .read(recommendationsListProvider.notifier)
                              .approve(rec.id);
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã duyệt đề xuất "${rec.deviceName ?? "Thiết bị"}" và tạo quy tắc tự động!',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: mint,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                            );
                          }
                        },
                        onReject: () async {
                          await ref
                              .read(recommendationsListProvider.notifier)
                              .reject(rec.id);
                        },
                        onDismiss: () async {
                          await ref
                              .read(recommendationsListProvider.notifier)
                              .dismiss(rec.id);
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const GlassListSkeleton(itemCount: 3, itemHeight: 180),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ErrorView(
              message: 'Không thể tải danh sách đề xuất: $e',
              onRetry: () =>
                  ref.read(recommendationsListProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final recsAsync = ref.watch(recommendationsListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final accent = theme.colorScheme.primary;

    if (widget.isEmbedded) {
      return _buildContent(context, recsAsync, isDark, mint, accent);
    }

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
                  _buildContent(context, recsAsync, isDark, mint, accent),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
