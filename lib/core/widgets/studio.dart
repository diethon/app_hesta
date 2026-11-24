import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bộ màu riêng cho Scene / Automation / Recommendation: trắng + xanh dương,
/// một màu nhấn duy nhất; xanh lá/đỏ chỉ dùng cho trạng thái.
/// Tự đổi theo chế độ sáng/tối của hệ thống.
class StudioColors {
  const StudioColors._({
    required this.bg,
    required this.card,
    required this.soft,
    required this.border,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.on,
    required this.off,
    required this.danger,
    required this.warn,
  });

  /// Nền trang.
  final Color bg;

  /// Nền thẻ.
  final Color card;

  /// Nền ô bên trong thẻ (dòng thiết bị, chip, khối KHI/THÌ…).
  final Color soft;
  final Color border;
  final Color text;
  final Color muted;
  final Color faint;

  /// Màu nhấn duy nhất: nút chính, toggle, link, tab đang chọn.
  final Color accent;

  /// Trạng thái đang bật / thành công.
  final Color on;

  /// Trạng thái đã tắt.
  final Color off;
  final Color danger;
  final Color warn;

  Color get accentSoft => accent.withValues(alpha: 0.10);

  static const light = StudioColors._(
    bg: Color(0xFFF5F8FB),
    card: Color(0xFFFFFFFF),
    soft: Color(0xFFF1F5FA),
    border: Color(0xFFE3EAF2),
    text: Color(0xFF0F1E33),
    muted: Color(0xFF5B6B80),
    faint: Color(0xFF8A98AB),
    accent: Color(0xFF2563EB),
    on: Color(0xFF16A34A),
    off: Color(0xFF94A3B8),
    danger: Color(0xFFDC2626),
    warn: Color(0xFFD97706),
  );

  static const dark = StudioColors._(
    bg: Color(0xFF0E1522),
    card: Color(0xFF162033),
    soft: Color(0xFF1D2940),
    border: Color(0xFF25324A),
    text: Color(0xFFE6EDF7),
    muted: Color(0xFF9AA8BC),
    faint: Color(0xFF6B7A90),
    accent: Color(0xFF5B8DEF),
    on: Color(0xFF22C55E),
    off: Color(0xFF64748B),
    danger: Color(0xFFF87171),
    warn: Color(0xFFF59E0B),
  );

  static StudioColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Nền phẳng của trang + đặt màu nhấn vào theme để các widget dùng chung
/// (chip lọc, segmented, status pill) lấy cùng một màu xanh.
class StudioBackground extends StatelessWidget {
  const StudioBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Theme(
      data: studioTheme(context),
      child: ColoredBox(color: c.bg, child: child),
    );
  }
}

/// Theme của 3 tính năng. Bottom sheet / dialog mở ra route mới nằm ngoài
/// [StudioBackground], nên bọc lại bằng `Theme(data: studioTheme(context))`.
ThemeData studioTheme(BuildContext context) {
  final c = StudioColors.of(context);
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(primary: c.accent, onSurface: c.text),
    dividerColor: c.border,
    // App bar trong suốt trên nền sáng: icon thanh trạng thái phải tối.
    appBarTheme: theme.appBarTheme.copyWith(
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    dialogTheme: theme.dialogTheme.copyWith(backgroundColor: c.card),
  );
}

/// Thẻ phẳng: nền đặc, viền mảnh, bóng rất nhẹ (không glow).
class StudioCard extends StatelessWidget {
  const StudioCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? c.border),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D0F1E33),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: color ?? c.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Ô icon tròn: nền nhạt của màu nhấn, icon màu nhấn (hoặc xám khi tắt).
class StudioIconTile extends StatelessWidget {
  const StudioIconTile({
    required this.icon,
    this.size = 44,
    this.active = true,
    super.key,
  });

  final IconData icon;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? c.accentSoft : c.soft,
      ),
      child: Icon(icon, size: size * 0.5, color: active ? c.accent : c.off),
    );
  }
}

/// Nhãn trạng thái nhỏ: chấm màu + chữ, không viền.
class StudioTag extends StatelessWidget {
  const StudioTag({required this.label, this.color, this.icon, super.key});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final tint = color ?? c.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color == null ? c.soft : tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

/// SnackBar thống nhất cho 3 tính năng.
void showStudioSnack(
  BuildContext context,
  String message, {
  bool success = true,
}) {
  final c = StudioColors.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: success ? c.text : c.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// "TURN_ON" + {brightness: 80} → "Bật · Độ sáng 80%". Mã lạ giữ nguyên
/// nhưng viết thường cho dễ đọc.
String describeAction(
  String action, {
  dynamic value,
  Map<String, dynamic> params = const {},
}) {
  const verbs = {
    'TURN_ON': 'Bật',
    'POWER_ON': 'Bật',
    'TURN_OFF': 'Tắt',
    'POWER_OFF': 'Tắt',
    'TOGGLE': 'Đảo bật/tắt',
    'SET_POWER': 'Bật/tắt nguồn',
    'SET_BRIGHTNESS': 'Chỉnh độ sáng',
    'SET_TEMPERATURE': 'Đặt nhiệt độ',
    'TEMPERATURE_PLUS': 'Tăng nhiệt độ',
    'TEMPERATURE_MINUS': 'Giảm nhiệt độ',
    'SET_RGB': 'Đổi màu đèn',
    'SET_COLOR': 'Đổi màu đèn',
    'SET_FAN': 'Chỉnh tốc độ quạt',
    'SET_MODE': 'Đổi chế độ',
    'SET_SWING': 'Đảo gió',
    'SET_TIMER': 'Hẹn giờ',
    'CANCEL_TIMER': 'Huỷ hẹn giờ',
    'OPEN': 'Mở',
    'CLOSE': 'Đóng',
    'STOP': 'Dừng',
    'SET_SPEED': 'Chỉnh tốc độ',
    'SET_STATE': 'Cài đặt nâng cao',
    'LOCK': 'Khoá',
    'UNLOCK': 'Mở khoá',
    'RUN_SCENE': 'Chạy kịch bản',
    'EXECUTE_SCENE': 'Chạy kịch bản',
    'NOTIFY': 'Gửi thông báo',
    'SEND_NOTIFICATION': 'Gửi thông báo',
  };
  final key = action.toUpperCase();
  final verb =
      verbs[key] ??
      (action.isEmpty
          ? 'Thực hiện'
          : '${action[0].toUpperCase()}${action.substring(1).toLowerCase().replaceAll('_', ' ')}');

  // Gộp tham số và giá trị (scene lưu "value", quy tắc lưu "parameters").
  final all = <String, dynamic>{
    ...params,
    if (value is Map) ...value.map((k, v) => MapEntry('$k', v)),
    if (value != null && value is! Map && '$value'.isNotEmpty)
      _valueKeyFor(key): value,
  };
  dynamic pick(List<String> keys) {
    for (final k in keys) {
      if (all[k] != null) return all[k];
    }
    return null;
  }

  String num0(dynamic v) =>
      v is double && v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  switch (key) {
    case 'SET_BRIGHTNESS':
      final v = pick(['level', 'brightness']);
      return v == null ? verb : 'Độ sáng ${num0(v)}%';
    case 'SET_TEMPERATURE':
      final v = pick(['temperature', 'temp']);
      return v == null ? verb : 'Nhiệt độ ${num0(v)}°C';
    case 'SET_SPEED' || 'SET_FAN':
      final v = pick(['speed', 'fan', 'level']);
      if (v == null) return 'Chỉnh tốc độ';
      return v is num ? 'Tốc độ ${num0(v)}%' : 'Tốc độ ${_fanName('$v')}';
    case 'SET_RGB' || 'SET_COLOR':
      final hex = pick(['color', 'hex']);
      final name = hex == null ? null : _colorNames['$hex'.toLowerCase()];
      return name != null ? 'Đổi màu $name' : 'Đổi màu đèn';
    case 'SET_MODE':
      final v = pick(['mode']);
      return v == null ? verb : 'Chế độ ${_modeName('$v')}';
    case 'SET_STATE':
      return 'Cài đặt nâng cao';
  }

  // Lệnh bật/tắt có thể kèm cài đặt (vd. điều hoà bật ở 26°C do gợi ý học được).
  final details = <String>{
    for (final e in all.entries) _describeParam(e.key, e.value),
  }.where((s) => s.isNotEmpty).toList();
  return details.isEmpty ? verb : '$verb · ${details.join(' · ')}';
}

const _colorNames = {
  '#ff4d4f': 'đỏ',
  '#faad14': 'vàng',
  '#ffc107': 'vàng',
  '#52c41a': 'xanh lá',
  '#1890ff': 'xanh dương',
  '#722ed1': 'tím',
  '#eb2f96': 'hồng',
  '#ffffff': 'trắng',
};

String _modeName(String v) =>
    const {
      'cool': 'làm mát',
      'heat': 'sưởi',
      'dry': 'hút ẩm',
      'fan': 'quạt',
      'auto': 'tự động',
    }[v.toLowerCase()] ??
    v.toLowerCase();

String _fanName(String v) =>
    const {'low': 'thấp', 'medium': 'vừa', 'high': 'cao', 'auto': 'tự động'}[v
        .toLowerCase()] ??
    v.toLowerCase();

String _valueKeyFor(String action) => switch (action) {
  'SET_BRIGHTNESS' => 'brightness',
  'SET_TEMPERATURE' => 'temperature',
  'SET_FAN' => 'fan',
  'SET_SPEED' => 'speed',
  'SET_MODE' => 'mode',
  _ => '',
};

String _describeParam(String key, dynamic value) {
  final k = key.toLowerCase();
  final v = value is double && value == value.roundToDouble()
      ? value.toInt()
      : value;
  if (v is bool || v is Map || v is List) return '';
  // Khoá kỹ thuật: thành phần màu, id nội bộ.
  if (const {'r', 'g', 'b', 'hex', 'state'}.contains(k)) return '';
  if (k.contains('bright') || k == 'level') return 'Độ sáng $v%';
  if (k.contains('temp')) return 'Nhiệt độ $v°C';
  if (k.contains('fan') || k.contains('speed')) return v is num ? 'Tốc độ $v%' : 'Tốc độ ${_fanName('$v')}';
  if (k.contains('position') || k.contains('percent')) return 'Mức $v%';
  if (k == 'mode') return 'Chế độ ${_modeName('$v')}';
  if (k.contains('color') || k == 'rgb') {
    return 'Màu ${_colorNames['$v'.toLowerCase()] ?? 'tuỳ chọn'}';
  }
  if (k == 'message' || k == 'title') return '“$v”';
  if (k.endsWith('id') || k.endsWith('ids')) return ''; // id nội bộ, không cho người dùng xem
  return k.isEmpty ? '$v' : '$key $v';
}

/// ISO 1=T2…7=CN (giống ScheduleRunner). Rỗng hoặc đủ 7 → "Hằng ngày".
String describeDays(List<int> days) {
  final s = days.toSet();
  if (s.isEmpty || s.length == 7) return 'Hằng ngày';
  if (s.length == 5 && s.containsAll([1, 2, 3, 4, 5])) return 'Thứ 2 – Thứ 6';
  if (s.length == 2 && s.containsAll([6, 7])) return 'Cuối tuần';
  final sorted = s.toList()..sort();
  return sorted.map((d) => d == 7 ? 'CN' : 'T${d + 1}').join(', ');
}

/// Khoảng thời gian thân thiện: "vừa xong", "5 phút trước", "hôm qua 21:30".
String describeWhen(DateTime? t) {
  if (t == null) return 'Chưa có';
  final local = t.toLocal();
  final diff = DateTime.now().difference(local);
  String hm() =>
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24 && local.day == DateTime.now().day) return 'Hôm nay ${hm()}';
  if (diff.inDays < 2) return 'Hôm qua ${hm()}';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${hm()}';
}

/// temperature GT 30 → "Nhiệt độ trên 30°C"; motion EQ true → "Có chuyển động".
String describeCondition(
  String attribute,
  String operator,
  dynamic value, {
  String? deviceName,
}) {
  final a = attribute.toLowerCase();
  final op = switch (operator.toUpperCase()) {
    'GT' => 'trên',
    'GTE' => 'từ',
    'LT' => 'dưới',
    'LTE' => 'tối đa',
    'NE' => 'khác',
    _ => 'là',
  };
  final negate = operator.toUpperCase() == 'NE';
  final prefix = deviceName == null || deviceName.isEmpty ? '' : '$deviceName: ';

  if (value is bool || value == 'true' || value == 'false') {
    final yes = (value == true || value == 'true') != negate;
    final text = switch (a) {
      _ when a.contains('motion') || a.contains('presence') || a.contains('occup') =>
        yes ? 'Có người/chuyển động' : 'Không có chuyển động',
      _ when a.contains('door') || a.contains('open') || a.contains('contact') =>
        yes ? 'Đang mở' : 'Đang đóng',
      _ when a.contains('smoke') || a.contains('gas') || a.contains('leak') =>
        yes ? 'Phát hiện bất thường' : 'Bình thường',
      _ => yes ? 'Đang bật' : 'Đang tắt',
    };
    return '$prefix$text';
  }

  final (label, unit) = switch (a) {
    _ when a.contains('temp') => ('Nhiệt độ', '°C'),
    _ when a.contains('humid') => ('Độ ẩm', '%'),
    _ when a.contains('bright') => ('Độ sáng', '%'),
    _ when a.contains('lux') || a.contains('illum') || a.contains('light') => ('Ánh sáng', ' lux'),
    _ when a.contains('co2') => ('CO₂', ' ppm'),
    _ when a.contains('pm') => ('Bụi mịn', ' µg/m³'),
    _ when a.contains('power') || a.contains('watt') => ('Công suất', ' W'),
    _ when a.contains('battery') => ('Pin', '%'),
    _ => (attribute, ''),
  };
  return '$prefix$label $op $value$unit';
}

/// SENSOR/SCHEDULE/EVENT → nhãn ngắn dễ hiểu.
String describeTrigger(String type) => switch (type.toUpperCase()) {
  'SCHEDULE' => 'Hẹn giờ',
  'EVENT' => 'Sự kiện',
  _ => 'Cảm biến',
};
