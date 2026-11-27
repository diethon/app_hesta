import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/studio.dart';
import '../../data/recommendation_providers.dart';
import '../../domain/recommendation_models.dart';

/// Trạng thái trợ lý thói quen bằng lời thường; số liệu mô hình chỉ dành cho kỹ thuật nên không hiện.
class MlModelStatusCard extends ConsumerWidget {
  const MlModelStatusCard({super.key});

  /// (tiêu đề trạng thái, câu giải thích, màu chấm trạng thái)
  (String, String, Color) _status(MlModelStatus m, StudioColors c) {
    if (m.isColdStart) {
      return (
        'Đang làm quen',
        'Hệ thống đang ghi nhận cách bạn dùng thiết bị. Gợi ý sẽ xuất hiện sau vài ngày.',
        c.warn,
      );
    }
    if (m.isTraining) {
      return (
        'Đang học',
        'Đang phân tích thói quen mới nhất của bạn…',
        c.accent,
      );
    }
    if (m.isUnavailable) {
      return (
        'Tạm ngưng',
        'Chưa kết nối được trợ lý AI. Bạn vẫn dùng app bình thường.',
        c.off,
      );
    }
    if (m.isNotTrained) {
      return (
        'Đang học thói quen của bạn',
        'HESTA vẫn đang làm quen với ngôi nhà. Hãy dùng thêm vài ngày để gợi ý chính xác hơn.',
        c.warn,
      );
    }
    return (
      'Đang hoạt động',
      'Cập nhật ${describeWhen(m.trainedAt).toLowerCase()}',
      c.on,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(mlModelStatusProvider);
    final c = StudioColors.of(context);

    return statusAsync.when(
      data: (model) {
        final (title, sub, dot) = _status(model, c);
        return StudioCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const StudioIconTile(icon: Icons.psychology_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trợ lý thói quen',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sub,
                style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
              ),
            ],
          ),
        );
      },
      loading: () => const GlassCardSkeleton(height: 96),
      error: (e, _) => StudioCard(
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: c.off),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chưa kết nối được trợ lý AI.',
                style: TextStyle(color: c.muted),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20, color: c.accent),
              tooltip: 'Thử lại',
              onPressed: () =>
                  ref.read(mlModelStatusProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}
