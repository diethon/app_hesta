import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const activeGlow = [
    BoxShadow(color: Color(0x330058BC), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Đổ bóng cho thẻ kính trên nền tối (đậm hơn soft để tách lớp).
  static const glassDark = [
    BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Glow accent cho phần tử đang active trên nền tối.
  static const accentGlow = [
    BoxShadow(color: Color(0x594C9EFF), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Glow mint cho trạng thái ON.
  static const mintGlow = [
    BoxShadow(color: Color(0x4D34D399), blurRadius: 20, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> colored(Color color, {double alpha = 0.3}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Bóng mềm phía dưới mô hình 3D trong hero card.
  static List<BoxShadow> heroModel(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.dark
          ? AppColors.orbAzure.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, 24),
    ),
  ];
}
