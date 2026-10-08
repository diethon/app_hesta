import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0058BC);
  static const primaryContainer = Color(0xFF0070EB);
  static const secondary = Color(0xFF006E28);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const tertiary = Color(0xFF894D00);
  static const tertiaryContainer = Color(0xFFAC6300);
  static const error = Color(0xFFBA1A1A);
  static const background = Color(0xFFFAF9FE);
  static const surface = Color(0xFFFAF9FE);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F3F8);
  static const surfaceContainer = Color(0xFFEEEDF3);
  static const surfaceContainerHigh = Color(0xFFE9E7ED);
  static const surfaceContainerHighest = Color(0xFFE3E2E7);
  static const onSurface = Color(0xFF1A1B1F);
  static const onSurfaceVariant = Color(0xFF414755);
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);

  // ── Midnight Aurora (dark-first glassmorphism) ────────────────────
  /// Accent chính trên nền tối — azure lạnh, gợi công nghệ tin cậy.
  static const auroraAccent = Color(0xFF4C9EFF);

  /// Trạng thái "đang bật / an toàn" — mint, chỉ dùng cho ON state.
  static const auroraMint = Color(0xFF34D399);

  /// Mint đậm dùng trên nền sáng để đảm bảo contrast.
  static const auroraMintOnLight = Color(0xFF1DA653);

  /// Cảnh báo / lỗi trên nền tối.
  static const auroraWarning = Color(0xFFFBBF24);
  static const auroraError = Color(0xFFF87171);

  /// Ba lớp canvas tối (trên → giữa → dưới) của gradient nền.
  static const auroraCanvasTop = Color(0xFF070B14);
  static const auroraCanvasMid = Color(0xFF0C1424);
  static const auroraCanvasBottom = Color(0xFF0A101E);

  /// Canvas sáng tương ứng cho light theme.
  static const auroraCanvasTopLight = Color(0xFFF4F6FC);
  static const auroraCanvasBottomLight = Color(0xFFFAF9FE);

  /// Màu orb ambient đặt sau lớp kính.
  static const orbAzure = Color(0xFF3B82F6);
  static const orbViolet = Color(0xFF8B5CF6);
  static const orbTeal = Color(0xFF2DD4BF);

  /// Chữ trên nền tối.
  static const onDark = Color(0xFFF1F3F9);
  static const onDarkMuted = Color(0xFFA6ADC2);
  static const onDarkFaint = Color(0xFF6B7288);
}
