import 'package:flutter/material.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HestaApp());
}

class HestaApp extends StatefulWidget {
  const HestaApp({super.key});

  @override
  State<HestaApp> createState() => _HestaAppState();
}

class _HestaAppState extends State<HestaApp> {
  final SessionController session = SessionController();

  @override
  void initState() {
    super.initState();
    session.restore();
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HESTA',
    debugShowCheckedModeBanner: false,
    theme: hestaTheme(),
    home: AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (!session.ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return session.user == null
            ? AuthScreen(session: session)
            : HomeShell(session: session, key: ValueKey(session.user!.id));
      },
    ),
  );
}
