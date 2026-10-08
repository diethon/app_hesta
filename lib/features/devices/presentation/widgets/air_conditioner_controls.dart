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

/// Bảng điều khiển Điều hòa chuyên nghiệp (Air Conditioner Controls)
/// Phù hợp hoàn toàn với API backend tại iot-ac.http:
/// - SET_POWER (on/off)
/// - SET_TEMPERATURE (20°C - 30°C)
/// - TEMPERATURE_PLUS (+1°C) / TEMPERATURE_MINUS (-1°C)
/// - SET_MODE (COOL, DRY, HEAT, AUTO)
/// - SET_FAN (AUTO, LOW, MID, HIGH)
/// - SET_SWING (đảo gió on/off)
/// - SET_TIMER (hẹn giờ tắt kèm halfHour) & CANCEL_TIMER
/// - Các chế độ thực tế: Turbo, Eco, Sleep Mode
class AirConditionerControls extends ConsumerStatefulWidget {
  const AirConditionerControls({
    required this.device,
    required this.accent,
    super.key,
  });

  final Device device;
  final Color accent;

  @override
  ConsumerState<AirConditionerControls> createState() => _AirConditionerControlsState();
}

class _AirConditionerControlsState extends ConsumerState<AirConditionerControls> {
  int _selectedTimerHour = 2;
  bool _isHalfHour = false;
  bool _showTimerSheet = false;

  Color _modeAccent(String mode) {
    return switch (mode.toUpperCase()) {
      'COOL' => const Color(0xFF00D2FF),
      'DRY' => const Color(0xFF00E5A3),
      'HEAT' => const Color(0xFFFF9500),
      'AUTO' => const Color(0xFFA855F7),
      _ => AppColors.auroraAccent,
    };
  }

  void _sendAcCommand(DeviceCommand command) {
    ref.read(devicesControllerProvider.notifier).updateDevice(
          widget.device.id,
          command,
        );
  }

  void _setPower(bool power) {
    HapticFeedback.mediumImpact();
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: 'SET_POWER',
      isOn: power,
    ));
  }

  void _adjustTemp(int delta) {
    HapticFeedback.selectionClick();
    final action = delta > 0 ? 'TEMPERATURE_PLUS' : 'TEMPERATURE_MINUS';
    final current = widget.device.temperature ?? 24;
    final next = (current + delta).clamp(20, 30);
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: action,
      temperature: next,
    ));
  }

  void _setTemp(int temp) {
    HapticFeedback.selectionClick();
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: 'SET_TEMPERATURE',
      temperature: temp.clamp(20, 30),
    ));
  }

  void _setMode(String mode) {
    HapticFeedback.selectionClick();
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: 'SET_MODE',
      mode: mode,
      isOn: true,
    ));
  }

  void _setFan(String fan) {
    HapticFeedback.selectionClick();
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: 'SET_FAN',
      fan: fan,
    ));
  }

  void _toggleSwing() {
    HapticFeedback.selectionClick();
    final current = widget.device.acSwing ?? false;
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: 'SET_SWING',
      swing: !current,
    ));
  }

  void _applyTimer() {
    HapticFeedback.mediumImpact();
    _sendAcCommand(DeviceCommand(
      isAc: true,
      acAction: 'SET_TIMER',
      hour: _selectedTimerHour,
      halfHour: _isHalfHour,
    ));
    setState(() => _showTimerSheet = false);
  }

  void _cancelTimer() {
    HapticFeedback.mediumImpact();
    _sendAcCommand(const DeviceCommand(
      isAc: true,
      cancelTimer: true,
      acAction: 'CANCEL_TIMER',
    ));
    setState(() => _showTimerSheet = false);
  }

  void _applyPreset(String preset) {
    HapticFeedback.mediumImpact();
    switch (preset) {
      case 'TURBO':
        _sendAcCommand(const DeviceCommand(
          isAc: true,
          mode: 'COOL',
          fan: 'HIGH',
          temperature: 20,
          isOn: true,
        ));
      case 'ECO':
        _sendAcCommand(const DeviceCommand(
          isAc: true,
          mode: 'COOL',
          fan: 'AUTO',
          temperature: 26,
          isOn: true,
        ));
      case 'SLEEP':
        _sendAcCommand(const DeviceCommand(
          isAc: true,
          mode: 'COOL',
          fan: 'LOW',
          swing: false,
          temperature: 27,
          isOn: true,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = widget.device;
    final isOn = device.isOn;
    final currentTemp = (device.temperature ?? 24).clamp(20, 30);
    final currentMode = (device.acMode ?? 'COOL').toUpperCase();
    final currentFan = (device.acFan ?? 'AUTO').toUpperCase();
    final isSwing = device.acSwing ?? false;
    final isTimerActive = device.timerEnabled ?? false;
    final timerHour = device.timerHour ?? 0;
    final timerHalfHour = device.timerHalfHour ?? false;
    final activeAccent = isOn ? _modeAccent(currentMode) : Colors.grey;

    return Column(
      children: [
        // ── KHỐI CHÍNH: NHIỆT ĐỘ & NGUỒN ──
        GlassContainer(
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Hàng trên: Chế độ đang chạy + Nút nguồn
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: activeAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getModeIcon(currentMode),
                          color: activeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOn ? 'ĐIỀU HÒA • $currentMode' : 'ĐIỀU HÒA • ĐÃ TẮT',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isOn ? activeAccent : Colors.white54,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            isOn
                                ? 'Quạt: $currentFan • Đảo gió: ${isSwing ? "Bật" : "Tắt"}'
                                : 'Nhấn nút nguồn để khởi động',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Nút nguồn tròn
                  GestureDetector(
                    onTap: () => _setPower(!isOn),
                    child: AnimatedContainer(
                      duration: GlassTokens.durationSlow,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn
                            ? activeAccent.withValues(alpha: 0.25)
                            : GlassTokens.fillDark,
                        border: Border.all(
                          color: isOn
                              ? activeAccent
                              : Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: isOn
                            ? GlassTokens.glow(activeAccent, intensity: 0.8)
                            : GlassTokens.shadowSoft,
                      ),
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        color: isOn ? Colors.white : Colors.white54,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Vùng hiển thị nhiệt độ lớn + nút tăng giảm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút Giảm (-1°C)
                  GlassIconButton(
                    icon: Icons.remove_rounded,
                    size: 60,
                    onTap: (isOn && currentTemp > 20) ? () => _adjustTemp(-1) : null,
                  ),

                  // Nhiệt độ trung tâm
                  Column(
                    children: [
                      Text(
                        '$currentTemp°',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                          color: isOn ? Colors.white : Colors.white38,
                          shadows: isOn
                              ? [
                                  Shadow(
                                    color: activeAccent.withValues(alpha: 0.6),
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      Text(
                        'Nhiệt độ mục tiêu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Nút Tăng (+1°C)
                  GlassIconButton(
                    icon: Icons.add_rounded,
                    size: 60,
                    onTap: (isOn && currentTemp < 30) ? () => _adjustTemp(1) : null,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Slider nhiệt độ trực quan (20°C - 30°C)
              Row(
                children: [
                  Text(
                    '20°',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GlassSlider(
                      value: ((currentTemp - 20) / 10.0).clamp(0.0, 1.0),
                      leadingIcon: Icons.ac_unit_rounded,
                      trailingIcon: Icons.wb_sunny_rounded,
                      onChanged: (val) {
                        final next = 20 + (val * 10).round();
                        if (next != currentTemp) {
                          _setTemp(next);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '30°',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── CHẾ ĐỘ ĐIỀU HÒA (COOL, DRY, HEAT, AUTO) ──
        GlassContainer(
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Text(
                  'CHẾ ĐỘ (MODE)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  _modeCard('COOL', 'Làm lạnh', Icons.ac_unit_rounded, currentMode),
                  const SizedBox(width: AppSpacing.sm),
                  _modeCard('DRY', 'Hút ẩm', Icons.water_drop_outlined, currentMode),
                  const SizedBox(width: AppSpacing.sm),
                  _modeCard('HEAT', 'Sưởi ấm', Icons.wb_sunny_rounded, currentMode),
                  const SizedBox(width: AppSpacing.sm),
                  _modeCard('AUTO', 'Tự động', Icons.auto_mode_rounded, currentMode),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── TỐC ĐỘ QUẠT (FAN) & ĐẢO GIÓ (SWING) ──
        GlassContainer(
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TỐC ĐỘ GIÓ (FAN)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'ĐẢO GIÓ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Tốc độ quạt (Segmented control)
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        _fanSegment('AUTO', 'Auto', currentFan),
                        const SizedBox(width: 4),
                        _fanSegment('LOW', '1', currentFan),
                        const SizedBox(width: 4),
                        _fanSegment('MID', '2', currentFan),
                        const SizedBox(width: 4),
                        _fanSegment('HIGH', '3', currentFan),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Nút bấm Đảo gió (Swing toggle)
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _toggleSwing,
                      child: AnimatedContainer(
                        duration: GlassTokens.durationFast,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSwing
                              ? activeAccent.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSwing
                                ? activeAccent
                                : Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: isSwing
                              ? GlassTokens.glow(activeAccent, intensity: 0.6)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.air_rounded,
                              color: isSwing ? Colors.white : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSwing ? 'BẬT' : 'TẮT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSwing ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── HẸN GIỜ (TIMER) & CÁC CHỨC NĂNG THỰC TẾ (TURBO, ECO, SLEEP) ──
        GlassContainer(
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng Hẹn Giờ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: isTimerActive
                            ? AppColors.auroraMint
                            : Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HẸN GIỜ TẮT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isTimerActive
                                ? 'Tự tắt sau: $timerHour giờ ${timerHalfHour ? "30 phút" : ""}'
                                : 'Chưa thiết lập hẹn giờ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isTimerActive
                                  ? AppColors.auroraMint
                                  : Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isTimerActive)
                    GestureDetector(
                      onTap: _cancelTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.auroraError.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.auroraError.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'HỦY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.auroraError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _showTimerSheet = !_showTimerSheet),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _showTimerSheet ? 'ĐÓNG' : 'CÀI ĐẶT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Bảng cài đặt giờ mở rộng khi bấm "CÀI ĐẶT"
              if (_showTimerSheet && !isTimerActive) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thời gian hẹn giờ:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '$_selectedTimerHour giờ ${_isHalfHour ? "30 phút" : "00 phút"}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: activeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Chọn số giờ
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [1, 2, 3, 4, 6, 8, 12].map((h) {
                      final selected = _selectedTimerHour == h;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTimerHour = h),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? activeAccent
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '${h}h',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: selected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Toggle thêm 30 phút
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cộng thêm 30 phút',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    GlassToggle(
                      value: _isHalfHour,
                      size: 0.8,
                      onChanged: (val) => setState(() => _isHalfHour = val),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text(
                      'KÍCH HOẠT HẸN GIỜ (SET_TIMER)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: AppSpacing.xs),

              // Hàng tính năng thực tế: TURBO, ECO, SLEEP
              Row(
                children: [
                  _presetButton('TURBO', 'Làm mát nhanh', Icons.bolt_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  _presetButton('ECO', 'Tiết kiệm điện', Icons.eco_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  _presetButton('SLEEP', 'Chế độ ngủ', Icons.bedtime_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeCard(
    String modeKey,
    String title,
    IconData icon,
    String currentMode,
  ) {
    final isSelected = currentMode == modeKey && widget.device.isOn;
    final color = _modeAccent(modeKey);

    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(modeKey),
        child: AnimatedContainer(
          duration: GlassTokens.durationFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: isSelected ? GlassTokens.glow(color, intensity: 0.7) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.white.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fanSegment(String fanKey, String label, String currentFan) {
    final isSelected = currentFan == fanKey && widget.device.isOn;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setFan(fanKey),
        child: AnimatedContainer(
          duration: GlassTokens.durationFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetButton(String presetKey, String label, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPreset(presetKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  presetKey,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    return switch (mode.toUpperCase()) {
      'COOL' => Icons.ac_unit_rounded,
      'DRY' => Icons.water_drop_outlined,
      'HEAT' => Icons.wb_sunny_rounded,
      'AUTO' => Icons.auto_mode_rounded,
      _ => Icons.ac_unit_rounded,
    };
  }
}
