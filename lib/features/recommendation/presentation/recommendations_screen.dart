import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_filter_chip.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/studio.dart';
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

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  String _selectedTab = 'pending'; // pending, approved, rejected, all_history
  bool _isGenerating = false;

  Future<void> _generate() async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _isGenerating = true);

    final count = await ref
        .read(recommendationsListProvider.notifier)
        .generate();

    if (!mounted) return;
    setState(() => _isGenerating = false);
    showStudioSnack(
      context,
      count > 0
          ? 'Tìm thấy $count gợi ý mới cho bạn.'
          : 'Chưa thấy thói quen nào lặp lại đủ rõ. Thử lại sau vài ngày nhé.',
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<Recommendation>> recsAsync,
  ) {
    final c = StudioColors.of(context);
    final allItems = recsAsync.valueOrNull ?? [];
    final pendingCount = allItems.where((r) => r.isPending).length;
    final approvedCount = allItems.where((r) => r.isApproved).length;
    final rejectedCount = allItems
        .where((r) => r.status.toUpperCase() == 'REJECTED')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ML Neural Model Status Card
        const MlModelStatusCard(),
        const SizedBox(height: AppSpacing.md),

        // Nút tìm gợi ý mới
        StudioCard(
          onTap: _isGenerating ? null : _generate,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (_isGenerating)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: c.accent,
                    ),
                  ),
                )
              else
                const StudioIconTile(icon: Icons.auto_awesome_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isGenerating ? 'Đang xem lại 30 ngày qua…' : 'Tìm gợi ý mới',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dựa trên cách bạn bật/tắt thiết bị hằng ngày',
                      style: TextStyle(fontSize: 12.5, color: c.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.faint),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sub-filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GlassFilterChip(
                label: 'Gợi ý mới ($pendingCount)',
                selected: _selectedTab == 'pending',
                onTap: () => setState(() => _selectedTab = 'pending'),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassFilterChip(
                label: 'Đã dùng ($approvedCount)',
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
                label: 'Lịch sử',
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
              if (_selectedTab == 'approved') return r.isApproved;
              if (_selectedTab == 'rejected') {
                return r.status.toUpperCase() == 'REJECTED';
              }
              return r.status != 'PENDING'; // all_history, same as the web
            }).toList();

            if (filtered.isEmpty) {
              String emptyMsg =
                  'Chưa có gợi ý mới.\nNhấn "Tìm gợi ý mới" ở trên để thử.';
              if (_selectedTab == 'approved') {
                emptyMsg = 'Bạn chưa dùng gợi ý nào.';
              } else if (_selectedTab == 'rejected') {
                emptyMsg = 'Bạn chưa từ chối gợi ý nào.';
              } else if (_selectedTab == 'all_history') {
                emptyMsg = 'Chưa có lịch sử.';
              }

              return Padding(
                padding: const EdgeInsets.only(top: 36, bottom: 44),
                child: EmptyView(
                  message: emptyMsg,
                  icon: Icons.auto_awesome_outlined,
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
                            showStudioSnack(
                              context,
                              'Đã tạo quy tắc cho ${rec.deviceName ?? "thiết bị"}.',
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
              message: 'Không tải được gợi ý. Kiểm tra kết nối rồi thử lại.',
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

    if (widget.isEmbedded) {
      return _buildContent(context, recsAsync);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                title: 'Gợi ý thông minh',
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  GlassIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Làm mới',
                    onTap: () {
                      ref.read(recommendationsListProvider.notifier).refresh();
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
                  _buildContent(context, recsAsync),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
