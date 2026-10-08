import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../domain/assistant_models.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  if (kUseMockData) {
    return MockAssistantRepository();
  }
  return ApiAssistantRepository(ref.watch(cloudApiClientProvider));
});

abstract interface class AssistantRepository {
  Future<AssistantReply> send(String message, List<ChatMessage> history);
}

/// Gọi smarthome-ai-service qua gateway: POST /api/v1/assistant/chat.
class ApiAssistantRepository implements AssistantRepository {
  ApiAssistantRepository(this._client);

  final NetworkClient _client;

  @override
  Future<AssistantReply> send(String message, List<ChatMessage> history) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/assistant/chat',
        data: {
          'message': message,
          'history': [
            for (final item in history)
              {'role': item.isUser ? 'user' : 'assistant', 'content': item.text},
          ],
        },
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final body = response.data;
      final data = body?['result'] ?? body?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('assistant response không hợp lệ');
      }
      return AssistantReply(
        reply: (data['reply'] as String?) ?? '',
        actionsPerformed: [
          for (final action in (data['actionsPerformed'] as List<dynamic>? ?? []))
            action.toString(),
        ],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const AssistantReply(
          reply:
              'Tính năng Trợ lý AI đang trong lộ trình tích hợp vào backend_hesta. '
              '(API /api/v1/assistant/chat chưa được backend_hesta mở endpoint)',
        );
      }
      rethrow;
    }
  }
}

/// Demo offline (USE_MOCK=true): trả lời giả lập, không gọi backend.
class MockAssistantRepository implements AssistantRepository {
  @override
  Future<AssistantReply> send(String message, List<ChatMessage> history) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const AssistantReply(
      reply:
          'Chế độ demo (USE_MOCK): mình chưa kết nối backend nên chưa điều '
          'khiển được thiết bị thật. Chạy app không kèm USE_MOCK để dùng AI thật nhé.',
    );
  }
}
