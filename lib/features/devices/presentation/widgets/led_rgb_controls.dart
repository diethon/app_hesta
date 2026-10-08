import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';
import '../../../../core/widgets/glass/glass.dart';
import '../../data/device_providers.dart';
import '../../domain/device.dart';
import 'color_spectrum_slider.dart';
import 'vertical_glass_slider.dart';

/// Bảng điều khiển LED RGB với:
/// 1. Tắt/bật với hiệu ứng ánh sáng đồng bộ.
/// 2. Dải màu RGB vuốt chọn mượt mà (không cần nhập tay chỉ số).
/// 3. Thanh trượt độ sáng kéo lên / kéo xuống trực quan.
/// 4. Các phím màu nhanh (presets) thẩm mỹ cao.
/// 5. Gọi API tương ứng từ iot-led.http (`POWER_ON`, `POWER_OFF`, `SET_RGB`, `SET_BRIGHTNESS`).
class LedRgbControls extends ConsumerStatefulWidget {
  const LedRgbControls({
    required this.device,
    required this.accent,
    super.key,
  });

  final Device device;
  final Color accent;

  @override
  ConsumerState<LedRgbControls> createState() => _LedRgbControlsState();
}

class _LedRgbControlsState extends ConsumerState<LedRgbControls> {
  late Color _currentColor;
  late double _brightness; // 0.0 -> 1.0

  static const List<(String, Color)> _presets = [
    ('Ấm', Color(0xFFFFE4C4)),
    ('Trắng', Color(0xFFF0F8FF)),
    ('Cyan', Color(0xFF00E5FF)),
    ('Xanh dương', Color(0xFF3B82F6)),
    ('Tím', Color(0xFFA855F7)),
    ('Cam', Color(0xFFFF7A00)),
    ('Đỏ neon', Color(0xFFFF2D55)),
    ('Xanh lục', Color(0xFF34D399)),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.device.rgbColor ?? widget.accent;
    _brightness = ((widget.device.brightness ?? 80) / 100.0).clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(LedRgbControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.device.rgbColor != null && widget.device.rgbColor != _currentColor) {
      _currentColor = widget.device.rgbColor!;
    }
    if (widget.device.brightness != null) {
      _brightness = (widget.device.brightness! / 100.0).clamp(0.0, 1.0);
    }
  }

  void _sendRgb(Color color) {
    setState(() => _currentColor = color);
    final r = (color.r * 255.0).round() & 0xff;
    final g = (color.g * 255.0).round() & 0xff;
    final b = (color.b * 255.0).round() & 0xff;
    ref.read(devicesControllerProvider.notifier).updateDevice(
          widget.device.id,
          DeviceCommand(
            r: r,
            g: g,
            b: b,
            isOn: true,
          ),
        );
  }

  void _sendBrightness(double value) {
    final intLevel = (value * 100).round();
    setState(() => _brightness = value);
    ref.read(devicesControllerProvider.notifier).updateDevice(
          widget.device.id,
          DeviceCommand(
            brightness: intLevel,
            isOn: intLevel > 0,
          ),
        );
  }

  void _togglePower() {
    HapticFeedback.mediumImpact();
    ref.read(devicesControllerProvider.notifier).updateDevice(
          widget.device.id,
          DeviceCommand(isOn: !widget.device.isOn),
        );
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final isOn = device.isOn;
    final effectiveColor = isOn ? _currentColor : Colors.grey;
    final rVal = (effectiveColor.r * 255.0).round() & 0xff;
    final gVal = (effectiveColor.g * 255.0).round() & 0xff;
    final bVal = (effectiveColor.b * 255.0).round() & 0xff;

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Thanh hiển thị ánh sáng LED mô phỏng (Live Light Bar) ──
          AnimatedContainer(
            duration: GlassTokens.durationSlow,
            height: 12,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: LinearGradient(
                colors: isOn
                    ? [
                        effectiveColor.withValues(alpha: 0.2),
                        effectiveColor,
                        effectiveColor.withValues(alpha: 0.2),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
              ),
              boxShadow: isOn
                  ? [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),

          // ── Khối điều khiển chính: Nút nguồn & Thanh kéo độ sáng ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cột trái: Nút nguồn + thông số
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Nút nguồn tròn kính với viền LED đổi màu
                        GestureDetector(
                          onTap: _togglePower,
                          child: AnimatedContainer(
                            duration: GlassTokens.durationSlow,
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOn
                                  ? effectiveColor.withValues(alpha: 0.2)
                                  : GlassTokens.fillDark,
                              border: Border.all(
                                color: isOn
                                    ? effectiveColor
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: isOn
                                  ? GlassTokens.glow(effectiveColor, intensity: 0.9)
                                  : GlassTokens.shadowSoft,
                            ),
                            child: Icon(
                              Icons.power_settings_new_rounded,
                              color: isOn ? Colors.white : Colors.white54,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOn ? 'ĐANG BẬT' : 'ĐÃ TẮT',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: isOn
                                          ? AppColors.auroraMint
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Độ sáng ${(_brightness * 100).round()}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'LED_RGB • IoT Control',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Thẻ màu hiện tại
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: effectiveColor,
                              boxShadow: isOn
                                  ? GlassTokens.glow(effectiveColor, intensity: 0.6)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isOn
                                ? 'RGB: ($rVal, $gVal, $bVal)'
                                : 'Đèn đang tắt',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Cột phải: Thanh kéo độ sáng lên - xuống
              VerticalGlassSlider(
                value: _brightness,
                height: 156,
                width: 64,
                accentColor: effectiveColor,
                label: 'Độ sáng',
                onChanged: (val) => setState(() => _brightness = val),
                onChangeEnd: _sendBrightness,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Dải màu cầu vồng (Continuous Color Spectrum) ──
          ColorSpectrumSlider(
            currentColor: _currentColor,
            onColorChanged: (c) => setState(() => _currentColor = c),
            onColorChangeEnd: _sendRgb,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Bảng màu mẫu chọn nhanh (Quick Presets) ──
          Text(
            'MÀU PHỔ BIẾN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (name, color) in _presets) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _sendRgb(color);
                      },
                      child: AnimatedContainer(
                        duration: GlassTokens.durationFast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _currentColor.toARGB32() == color.toARGB32() && isOn
                              ? color.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: _currentColor.toARGB32() == color.toARGB32() && isOn
                                ? color
                                : Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: _currentColor.toARGB32() == color.toARGB32() && isOn
                              ? GlassTokens.glow(color, intensity: 0.7)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
