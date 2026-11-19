import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/studio.dart';
import '../data/scene_providers.dart';
import '../domain/scene.dart';

class SceneHistoryScreen extends ConsumerWidget {
  const SceneHistoryScreen({required this.scene, super.key});

  final Scene scene;

  static String _source(String raw) => switch (raw.toUpperCase()) {
    'MANUAL' || 'USER' || 'APP' => 'Bạn chạy thủ công',
    'SCHEDULE' || 'SCHEDULED' => 'Theo lịch hẹn giờ',
    'AUTOMATION' || 'RULE' => 'Do quy tắc tự động',
    'VOICE' => 'Bằng giọng nói',
    'RECOMMENDATION' => 'Từ gợi ý AI',
    _ => 'Tự động',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sceneExecutionsProvider(scene.id));
    final names = {
      for (final a in scene.actions) a.targetDeviceId: a.targetDeviceName,
    };

    return StudioBackground(
      child: Builder(
        builder: (context) {
          final c = StudioColors.of(context);
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 68,
                  flexibleSpace: GlassAppBar(
                    title: 'Lịch sử chạy',
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
                            message: 'Ngữ cảnh này chưa chạy lần nào.',
                            icon: Icons.history_rounded,
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = executions[index];
                          final ok = item.status.toUpperCase() == 'SUCCESS';
                          final failed = item.resultDetail
                              .where((d) => !d.success)
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StudioCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        ok
                                            ? Icons.check_circle_rounded
                                            : Icons.error_rounded,
                                        size: 20,
                                        color: ok ? c.on : c.danger,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ok
                                              ? 'Chạy thành công'
                                              : failed > 0
                                              ? '$failed thiết bị không phản hồi'
                                              : 'Chạy không thành công',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: c.text,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        describeWhen(item.startedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.faint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 28),
                                    child: Text(
                                      _source(item.triggerSource),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: c.muted,
                                      ),
                                    ),
                                  ),
                                  if (item.resultDetail.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: c.soft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          for (final d in item.resultDetail)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    d.success
                                                        ? Icons.check_rounded
                                                        : Icons.close_rounded,
                                                    size: 15,
                                                    color: d.success
                                                        ? c.on
                                                        : c.danger,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      '${names[d.deviceId] ?? 'Thiết bị'}: ${describeAction(d.action)}',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: c.text,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }, childCount: executions.length),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: ErrorView(
                        message: 'Không tải được lịch sử. Thử lại sau nhé.',
                        onRetry: () =>
                            ref.invalidate(sceneExecutionsProvider(scene.id)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
