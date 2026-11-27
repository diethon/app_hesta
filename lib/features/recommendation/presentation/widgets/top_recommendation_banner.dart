import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/studio.dart';
import '../../data/recommendation_providers.dart';
import '../../domain/recommendation_models.dart';
import 'recommendation_item_card.dart';

/// Home-screen suggestion, like the web SpotlightRecommendationBanner: hidden when there is none or it fails,
/// so the home screen never breaks because of it.
class TopRecommendationBanner extends ConsumerWidget {
  const TopRecommendationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(topRecommendationProvider).valueOrNull;
    if (rec == null) return const SizedBox.shrink();
    final c = StudioColors.of(context);
    final notifier = ref.read(recommendationsListProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gợi ý cho bạn',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/recommendations'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RecommendationItemCard(
            recommendation: rec,
            onApprove: () async {
              if (!await _confirmApprove(context, rec)) return;
              final ok = await notifier.approve(rec.id);
              if (context.mounted) {
                showStudioSnack(
                  context,
                  ok
                      ? 'Đã tạo quy tắc cho ${rec.deviceName ?? "thiết bị"}.'
                      : 'Không thể xử lý gợi ý',
                );
              }
            },
            onReject: () => notifier.reject(rec.id),
            onDismiss: () => notifier.dismiss(rec.id),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmApprove(BuildContext context, Recommendation rec) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: studioTheme(context),
        child: AlertDialog(
          title: const Text('Áp dụng thói quen này?'),
          content: Text(
            'HESTA sẽ thiết lập lịch tự động cho ${rec.deviceName ?? 'thiết bị'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }
}
