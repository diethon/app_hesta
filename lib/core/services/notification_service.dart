import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  // flutter_local_notifications chỉ hỗ trợ mobile/desktop Apple/Linux;
  // các nền tảng khác (web, Windows dev) dùng bản no-op.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    return LocalNotificationService();
  }
  return DeferredNotificationService();
});

abstract interface class NotificationService {
  Future<void> initialize();

  Future<void> requestPermissionWithContext();

  Future<void> registerDeviceToken(String token);

  Future<void> handleNotificationTap(Uri deepLink);

  /// Hiện notification trên thanh trạng thái hệ thống (app đang foreground).
  Future<void> showLocal({required String title, required String body});
}

class DeferredNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissionWithContext() async {}

  @override
  Future<void> registerDeviceToken(String token) async {}

  @override
  Future<void> handleNotificationTap(Uri deepLink) async {}

  @override
  Future<void> showLocal({required String title, required String body}) async {}
}

/// Local notification qua flutter_local_notifications — dùng cho thông báo
/// automation khi app đang chạy (chưa có FCM/phần cứng).
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _notificationId = 0;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'automation',
        'Automation',
        channelDescription: 'Thông báo khi automation/hẹn giờ được thực thi',
        importance: Importance.high,
        priority: Priority.high,
      );

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<void> requestPermissionWithContext() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> registerDeviceToken(String token) async {
    // FCM chưa dùng — sẽ nối khi có phần cứng/push từ server.
  }

  @override
  Future<void> handleNotificationTap(Uri deepLink) async {}

  @override
  Future<void> showLocal({required String title, required String body}) async {
    await initialize();
    await _plugin.show(
      _notificationId++,
      title,
      body,
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}
