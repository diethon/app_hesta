import 'package:flutter/material.dart';

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

  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.auto_awesome_rounded;
    }
    return iconMap[iconName.toLowerCase()] ?? Icons.auto_awesome_rounded;
  }
}
