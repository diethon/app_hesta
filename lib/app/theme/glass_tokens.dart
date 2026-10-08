import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token cho toàn bộ hiệu ứng kính (Midnight Aurora design system).
///
/// Mọi giá trị blur / opacity / gradient viền / glow của các thẻ kính
/// đều lấy từ đây — cấm hardcode trong screen.
abstract final class GlassTokens {
  // ── Blur sigma ────────────────────────────────────────────────────
  static const blurSm = 12.0;
  static const blurMd = 20.0;
  static const blurLg = 28.0;

  // ── Fill (màu nền của tấm kính) ───────────────────────────────────
  static const fillDark = Color(0x12FFFFFF); // white 7%
  static const fillDarkActive = Color(0x1FFFFFFF); // white 12%
  static const fillLight = Color(0x9EFFFFFF); // white 62%
  static const fillLightActive = Color(0xC7FFFFFF); // white 78%

  static Color fill(Brightness brightness, {bool active = false}) {
    return brightness == Brightness.dark
        ? (active ? fillDarkActive : fillDark)
        : (active ? fillLightActive : fillLight);
  }

  // ── Viền gradient (bắt sáng cạnh trên-trái) ──────────────────────
  static const borderWidth = 1.0;

  static Gradient borderGradient(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0x38FFFFFF), const Color(0x0AFFFFFF)]
          : [const Color(0xBFFFFFFF), const Color(0x40FFFFFF)],
    );
  }

  static Color borderSolid(Brightness brightness, {bool active = false}) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return active ? const Color(0x5C4C9EFF) : const Color(0x24FFFFFF);
    }
    return active ? const Color(0x590058BC) : const Color(0x8CFFFFFF);
  }

  // ── Glow ─────────────────────────────────────────────────────────
  static List<BoxShadow> glow(Color color, {double intensity = 1}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35 * intensity),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // ── Ambient orbs (đặt sau lớp kính, do AmbientBackground vẽ) ─────
  static const orbBlur = 90.0;
  static const orbAlphaDark = [0.20, 0.14, 0.12];
  static const orbAlphaLight = [0.10, 0.07, 0.06];
  static const orbColors = [
    AppColors.orbAzure,
    AppColors.orbViolet,
    AppColors.orbTeal,
  ];

  // ── Motion ───────────────────────────────────────────────────────
  static const curve = Curves.easeOutCubic;
  static const durationFast = Duration(milliseconds: 200);
  static const durationMed = Duration(milliseconds: 280);
  static const durationSlow = Duration(milliseconds: 350);
  static const pressedScale = 0.97;
}
