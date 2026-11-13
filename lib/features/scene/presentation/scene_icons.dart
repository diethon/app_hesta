import 'package:flutter/material.dart';

class SceneAtmosphere {
  const SceneAtmosphere({
    required this.icon,
    required this.accentColor,
    required this.gradient,
    required this.vietnameseLabel,
  });

  final IconData icon;
  final Color accentColor;
  final List<Color> gradient;
  final String vietnameseLabel;
}

abstract final class SceneIcons {
  static const Map<String, IconData> iconMap = {
    'home': Icons.home_rounded,
    'sun': Icons.wb_sunny_rounded,
    'morning': Icons.wb_sunny_rounded,
    'moon': Icons.nightlight_round,
    'night': Icons.nightlight_round,
    'bed': Icons.bed_rounded,
    'movie': Icons.movie_rounded,
    'tv': Icons.tv_rounded,
    'coffee': Icons.coffee_rounded,
    'music': Icons.music_note_rounded,
    'book': Icons.menu_book_rounded,
    'briefcase': Icons.work_rounded,
    'work': Icons.work_rounded,
    'shield': Icons.shield_rounded,
    'security': Icons.security_rounded,
    'utensils': Icons.restaurant_rounded,
    'zap': Icons.bolt_rounded,
    'flame': Icons.local_fire_department_rounded,
    'wind': Icons.air_rounded,
    'sparkles': Icons.auto_awesome_rounded,
    'bell': Icons.notifications_rounded,
    'exit': Icons.logout_rounded,
    'party': Icons.celebration_rounded,
  };

  static final Map<String, SceneAtmosphere> _atmosphereMap = {
    'home': const SceneAtmosphere(
      icon: Icons.home_rounded,
      accentColor: Color(0xFF38BDF8), // Sky Blue
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      vietnameseLabel: 'Ở nhà',
    ),
    'sun': const SceneAtmosphere(
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24), // Amber Sun
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      vietnameseLabel: 'Buổi sáng',
    ),
    'morning': const SceneAtmosphere(
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFBBF24),
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      vietnameseLabel: 'Buổi sáng',
    ),
    'moon': const SceneAtmosphere(
      icon: Icons.nightlight_round,
      accentColor: Color(0xFF818CF8), // Indigo
      gradient: [Color(0xFF6366F1), Color(0xFF4338CA)],
      vietnameseLabel: 'Buổi tối',
    ),
    'night': const SceneAtmosphere(
      icon: Icons.nightlight_round,
      accentColor: Color(0xFF818CF8),
      gradient: [Color(0xFF6366F1), Color(0xFF4338CA)],
      vietnameseLabel: 'Buổi tối',
    ),
    'bed': const SceneAtmosphere(
      icon: Icons.bed_rounded,
      accentColor: Color(0xFFA78BFA), // Lavender
      gradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      vietnameseLabel: 'Giấc ngủ',
    ),
    'movie': const SceneAtmosphere(
      icon: Icons.movie_rounded,
      accentColor: Color(0xFFF472B6), // Neon Pink/Rose
      gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
      vietnameseLabel: 'Xem phim',
    ),
    'tv': const SceneAtmosphere(
      icon: Icons.tv_rounded,
      accentColor: Color(0xFFC084FC),
      gradient: [Color(0xFF9333EA), Color(0xFF6B21A8)],
      vietnameseLabel: 'Giải trí',
    ),
    'coffee': const SceneAtmosphere(
      icon: Icons.coffee_rounded,
      accentColor: Color(0xFFFB923C), // Warm Coffee
      gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
      vietnameseLabel: 'Cà phê',
    ),
    'music': const SceneAtmosphere(
      icon: Icons.music_note_rounded,
      accentColor: Color(0xFF34D399), // Mint Green
      gradient: [Color(0xFF10B981), Color(0xFF047857)],
      vietnameseLabel: 'Âm nhạc',
    ),
    'book': const SceneAtmosphere(
      icon: Icons.menu_book_rounded,
      accentColor: Color(0xFF2DD4BF), // Teal
      gradient: [Color(0xFF0D9488), Color(0xFF0F766E)],
      vietnameseLabel: 'Đọc sách',
    ),
    'work': const SceneAtmosphere(
      icon: Icons.work_rounded,
      accentColor: Color(0xFF60A5FA), // Azure
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      vietnameseLabel: 'Làm việc',
    ),
    'briefcase': const SceneAtmosphere(
      icon: Icons.work_rounded,
      accentColor: Color(0xFF60A5FA),
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      vietnameseLabel: 'Công việc',
    ),
    'shield': const SceneAtmosphere(
      icon: Icons.shield_rounded,
      accentColor: Color(0xFF10B981), // Emerald
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      vietnameseLabel: 'An ninh',
    ),
    'security': const SceneAtmosphere(
      icon: Icons.security_rounded,
      accentColor: Color(0xFF10B981),
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      vietnameseLabel: 'Bảo vệ',
    ),
    'utensils': const SceneAtmosphere(
      icon: Icons.restaurant_rounded,
      accentColor: Color(0xFFF97316),
      gradient: [Color(0xFFEA580C), Color(0xFF9A3412)],
      vietnameseLabel: 'Ăn uống',
    ),
    'zap': const SceneAtmosphere(
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFFFBBF24),
      gradient: [Color(0xFFEAB308), Color(0xFFA16207)],
      vietnameseLabel: 'Tiết kiệm điện',
    ),
    'party': const SceneAtmosphere(
      icon: Icons.celebration_rounded,
      accentColor: Color(0xFFE879F9), // Fuchsia
      gradient: [Color(0xFFC026D3), Color(0xFF86198F)],
      vietnameseLabel: 'Tiệc tùng',
    ),
    'exit': const SceneAtmosphere(
      icon: Icons.logout_rounded,
      accentColor: Color(0xFF94A3B8), // Slate
      gradient: [Color(0xFF475569), Color(0xFF334155)],
      vietnameseLabel: 'Rời nhà',
    ),
    'sparkles': const SceneAtmosphere(
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFFA855F7), // Purple Sparkle
      gradient: [Color(0xFF9333EA), Color(0xFF6B21A8)],
      vietnameseLabel: 'Kỳ diệu',
    ),
  };

  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.auto_awesome_rounded;
    }
    return iconMap[iconName.toLowerCase()] ?? Icons.auto_awesome_rounded;
  }

  static SceneAtmosphere getAtmosphere(String? iconName) {
    final key = (iconName ?? '').toLowerCase().trim();
    return _atmosphereMap[key] ??
        SceneAtmosphere(
          icon: getIcon(iconName),
          accentColor: const Color(0xFF4C9EFF),
          gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          vietnameseLabel: 'Ngữ cảnh',
        );
  }
}
