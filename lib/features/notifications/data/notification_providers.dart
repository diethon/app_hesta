import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../authentication/presentation/auth_controller.dart';
import '../domain/app_notification.dart';
import 'notification_repository.dart';

import '../../home/data/home_providers.dart';

/// Key toàn cục để hiện SnackBar thông báo từ bất kỳ màn hình nào.
final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

/// Giữ alive từ SynaApp để nhận realtime kể cả khi chưa mở màn Notifications.
final notificationsControllerProvider =
    StateNotifierProvider<
      NotificationsController,
      AsyncValue<List<AppNotification>>
    >((ref) {
      final controller = NotificationsController(
        ref.watch(notificationRepositoryProvider),
        notificationService: ref.watch(notificationServiceProvider),
        messengerKey: ref.watch(scaffoldMessengerKeyProvider),
      );

      final userId = ref.watch(
        authControllerProvider.select((state) => state.session?.userId),
      );
      final homeId = ref.watch(currentHomeIdProvider);

      if (userId != null) {
        controller.load();
        if (!kUseMockData) {
          final webSocket = ref.watch(notificationWebSocketServiceProvider);
          final subs = <StreamSubscription<dynamic>>[];

          // 1. Nhận thông báo từ topic của home: /topic/homes/{homeId}/events
          if (homeId != null) {
            subs.add(
              webSocket.subscribeJson('/topic/homes/$homeId/events').listen((event) {
                if (event['type'] == 'NOTIFICATION_CREATED') {
                  final data = event['data'];
                  if (data is Map<String, dynamic>) {
                    controller.onRealtime(data);
                  }
                }
              }),
            );
          }

          // 2. Kênh fallback theo userId
          subs.add(
            webSocket
                .subscribeJson('/topic/users/$userId/notifications')
                .listen(controller.onRealtime),
          );

          ref.onDispose(() {
            for (final sub in subs) {
              sub.cancel();
            }
          });

          unawaited(
            ref.read(notificationServiceProvider).requestPermissionWithContext(),
          );
        }
      }
      return controller;
    });

class NotificationsController
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsController(
    this._repository, {
    required NotificationService notificationService,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) : _notificationService = notificationService,
       _messengerKey = messengerKey,
       super(const AsyncValue.loading());

  final NotificationRepository _repository;
  final NotificationService _notificationService;
  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  Future<void> load() async {
    state = await AsyncValue.guard(_repository.getNotifications);
  }

  /// Notification mới từ WebSocket: thêm vào đầu danh sách, hiện notification
  /// trên thanh trạng thái + SnackBar trong app.
  void onRealtime(Map<String, dynamic> json) {
    final AppNotification notification;
    try {
      notification = AppNotification.fromJson(json);
    } catch (_) {
      return;
    }
    final current = state.valueOrNull ?? const <AppNotification>[];
    if (current.any((item) => item.id == notification.id)) {
      return;
    }
    state = AsyncValue.data([notification, ...current]);

    unawaited(
      _notificationService.showLocal(
        title: notification.title,
        body: notification.body,
      ),
    );
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text('${notification.title}\n${notification.body}'),
      ),
    );
  }

  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncValue.data([
      for (final item in current)
        item.id == id ? item.copyWith(read: true) : item,
    ]);
    try {
      await _repository.markRead(id);
    } catch (_) {
      // Giữ trạng thái optimistic; lần load sau sẽ đồng bộ lại từ server.
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final unread = current.where((item) => !item.read).toList();
    state = AsyncValue.data([
      for (final item in current) item.copyWith(read: true),
    ]);
    for (final item in unread) {
      try {
        await _repository.markRead(item.id);
      } catch (_) {
        // bỏ qua — đồng bộ lại ở lần load sau
      }
    }
  }
}
