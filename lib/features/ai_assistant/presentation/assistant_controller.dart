import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/assistant_repository.dart';
import '../domain/assistant_models.dart';

final assistantControllerProvider =
    StateNotifierProvider<AssistantController, AssistantChatState>((ref) {
      return AssistantController(ref.watch(assistantRepositoryProvider));
    });

class AssistantChatState {
  const AssistantChatState({this.messages = const [], this.isSending = false});

  final List<ChatMessage> messages;
  final bool isSending;

  AssistantChatState copyWith({List<ChatMessage>? messages, bool? isSending}) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class AssistantController extends StateNotifier<AssistantChatState> {
  AssistantController(this._repository) : super(const AssistantChatState());

  final AssistantRepository _repository;

  /// [errorFallback] là chuỗi l10n hiển thị khi backend lỗi.
  Future<void> send(String text, {required String errorFallback}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) {
      return;
    }
    final history = state.messages;
    state = state.copyWith(
      messages: [...history, ChatMessage(text: trimmed, isUser: true)],
      isSending: true,
    );
    try {
      final reply = await _repository.send(trimmed, history);
      final replyText = reply.reply.trim().isEmpty
          ? errorFallback
          : reply.reply.trim();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: replyText, isUser: false),
        ],
        isSending: false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: errorFallback, isUser: false),
        ],
        isSending: false,
      );
    }
  }
}
