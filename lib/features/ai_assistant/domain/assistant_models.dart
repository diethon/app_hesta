class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class AssistantReply {
  const AssistantReply({required this.reply, this.actionsPerformed = const []});

  final String reply;

  /// Mô tả các hành động backend đã thực thi (bật/tắt thiết bị, tạo hẹn giờ).
  final List<String> actionsPerformed;
}
