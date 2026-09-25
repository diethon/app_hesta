import 'package:flutter/material.dart';

abstract final class HestaColors {
  static const app = Color(0xFFF8FCFF);
  static const surface = Colors.white;
  static const sidebar = Color(0xFFEEF7FB);
  static const line = Color(0xFFDCEAF2);
  static const primary = Color(0xFF5BC0EB);
  static const mint = Color(0xFF7BDCB5);
  static const text = Color(0xFF3A4A5A);
  static const muted = Color(0xFF6B7C8F);
  static const success = Color(0xFF6EDFA3);
  static const successSoft = Color(0xFFE8FAF0);
  static const offSoft = Color(0xFFF4F8FB);
  static const error = Color(0xFFFF8A8A);
  static const errorSoft = Color(0xFFFFF0F0);
}

ThemeData hestaTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: HestaColors.primary, brightness: Brightness.light).copyWith(
    primary: HestaColors.primary,
    secondary: HestaColors.mint,
    surface: HestaColors.surface,
    error: HestaColors.error,
    onSurface: HestaColors.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: HestaColors.app,
    appBarTheme: const AppBarTheme(backgroundColor: HestaColors.app, foregroundColor: HestaColors.text, centerTitle: false),
    cardTheme: CardThemeData(color: HestaColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: HestaColors.line))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HestaColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: HestaColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: HestaColors.line)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: HestaColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(44, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    )),
  );
}
