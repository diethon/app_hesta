import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/studio.dart';
import '../../data/recommendation_providers.dart';
import '../../domain/recommendation_models.dart';

class MlModelStatusCard extends ConsumerStatefulWidget {
  const MlModelStatusCard({super.key});

  @override
  ConsumerState<MlModelStatusCard> createState() => _MlModelStatusCardState();
}

class _MlModelStatusCardState extends ConsumerState<MlModelStatusCard> {
  bool _isRetraining = false;
  bool _showDetails = false;

  Future<void> _handleRetrain() async {
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _isRetraining = true);

    final result = await ref.read(mlModelStatusProvider.notifier).retrain();

    if (!mounted) return;
    setState(() => _isRetraining = false);
    if (result != null) {
      showStudioSnack(
        context,
        result.isReady
            ? 'Đã học lại xong thói quen của bạn.'
            : result.isUnavailable
            ? 'Trợ lý AI đang tạm ngưng, vui lòng thử lại sau.'
            : 'Trợ lý AI vẫn đang xử lý, thử lại sau ít phút.',
        success: result.isReady,
      );
    }
  }

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
      return ('Đang học', 'Đang phân tích thói quen mới nhất của bạn…', c.accent);
    }
    if (m.isUnavailable) {
      return ('Tạm ngưng', 'Chưa kết nối được trợ lý AI. Bạn vẫn dùng app bình thường.', c.off);
    }
    if (m.isNotTrained) {
      return ('Chưa sẵn sàng', 'Chưa có đủ dữ liệu. Nhấn "Học lại" sau khi dùng thiết bị vài ngày.', c.warn);
    }
    return ('Đang hoạt động', 'Cập nhật ${describeWhen(m.trainedAt).toLowerCase()}', c.on);
  }

  @override
  Widget build(BuildContext context) {
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
                  TextButton.icon(
                    onPressed: _isRetraining ? null : _handleRetrain,
                    style: TextButton.styleFrom(foregroundColor: c.accent),
                    icon: _isRetraining
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.accent,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_isRetraining ? 'Đang học…' : 'Học lại'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sub,
                style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
              ),

              // Số liệu kỹ thuật: ẩn mặc định, chỉ mở khi cần.
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.faint,
                        ),
                      ),
                      Icon(
                        _showDetails
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: c.faint,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showDetails)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _DetailRow('Độ chính xác', '${model.accuracyPercent}%'),
                      _DetailRow('Số lần ghi nhận', '${model.trainSamples ?? 0}'),
                      _DetailRow(
                        'Chỉ gợi ý khi chắc chắn từ',
                        '${(model.confidenceThreshold * 100).round()}%',
                      ),
                      _DetailRow('Phiên bản', '${model.modelType} v${model.version}'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const GlassCardSkeleton(height: 120),
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
              onPressed: () => ref.read(mlModelStatusProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: c.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }
}
