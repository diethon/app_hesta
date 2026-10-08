class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      body: (json['message'] ?? json['body'] ?? '') as String,
      type: (json['type'] as String?) ?? 'SYSTEM',
      read: (json['isRead'] ?? json['read'] ?? false) as bool,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String body;

  /// SECURITY | DEVICE | AUTOMATION | SYSTEM.
  final String type;
  final bool read;
  final DateTime createdAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
