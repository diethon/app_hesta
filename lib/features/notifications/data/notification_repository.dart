import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (kUseMockData) {
    return MockNotificationRepository();
  }
  return ApiNotificationRepository(ref.watch(cloudApiClientProvider));
});

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getNotifications();

  Future<void> markRead(String id);
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final NetworkClient _client;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/v1/notifications',
      queryParameters: {'page': 0, 'size': 50},
    );
    final body = response.data;
    final result = body?['result'] ?? body?['data'];
    final content = result is Map<String, dynamic>
        ? result['content']
        : (result is List ? result : null);

    if (content is! List) {
      return const [];
    }
    return content
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _client.dio.patch<void>('/api/v1/notifications/$id/read');
  }
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> getNotifications() async {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'mock-1',
        title: 'Automation: Bật đèn 18:00',
        body: 'Đã thực hiện "Bật đèn 18:00": Đèn phòng khách.',
        type: 'AUTOMATION',
        read: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: 'mock-2',
        title: 'Chào mừng đến Syna Home',
        body: 'Tài khoản demo của bạn đã sẵn sàng.',
        type: 'SYSTEM',
        read: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  @override
  Future<void> markRead(String id) async {}
}
