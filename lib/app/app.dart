import 'package:flutter/material.dart';
import 'package:syna/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/data/notification_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SynaApp extends ConsumerWidget {
  const SynaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Giữ controller thông báo sống toàn app: nhận WebSocket realtime và hiện
    // notification thanh trạng thái + SnackBar kể cả khi không ở màn Notifications.
    ref.watch(notificationsControllerProvider);

    return MaterialApp.router(
      title: 'Syna',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
