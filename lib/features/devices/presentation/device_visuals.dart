import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/device.dart';

/// Map thuần UI: DeviceType/id → icon, màu glow, ảnh sản phẩm.
/// Ảnh nào chưa có asset thật thì trả null (card sẽ fallback icon tile)
/// — danh sách còn thiếu ghi ở assets/ASSETS_NEEDED.md.
abstract final class DeviceVisuals {
  static IconData icon(DeviceType type) => switch (type) {
    DeviceType.light => Icons.lightbulb_rounded,
    DeviceType.ledRgb => Icons.palette_rounded,
    DeviceType.thermostat => Icons.ac_unit_rounded,
    DeviceType.lock => Icons.lock_rounded,
    DeviceType.speaker => Icons.speaker_rounded,
    DeviceType.camera => Icons.videocam_rounded,
    DeviceType.fan => Icons.air_rounded,
    DeviceType.sensor => Icons.sensors_rounded,
  };

  /// Màu accent/glow theo loại thiết bị (dark-first).
  static Color accent(DeviceType type, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (type) {
      DeviceType.light => AppColors.auroraWarning,
      DeviceType.ledRgb => AppColors.orbViolet,
      DeviceType.thermostat =>
        isDark ? AppColors.auroraAccent : AppColors.primary,
      DeviceType.lock =>
        isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight,
      DeviceType.speaker => AppColors.orbViolet,
      DeviceType.camera => isDark ? AppColors.auroraAccent : AppColors.primary,
      DeviceType.fan => AppColors.orbTeal,
      DeviceType.sensor =>
        isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight,
    };
  }

  /// Ảnh sản phẩm PNG (nền trong) cho grid card trong phòng.
  static String? productImage(Device device) {
    const byId = <String, String>{
      'living-ceiling':
          'assets/images/room_devices/livingroom_devices/celling light.png',
      'living-lamp':
          'assets/images/room_devices/livingroom_devices/pendant light.png',
      'living-led-rgb':
          'assets/images/room_devices/bedroom_devices/led rgb.png',
      'living-ac':
          'assets/images/room_devices/bedroom_devices/Air conditioner.png',
      'bedroom-ac':
          'assets/images/room_devices/bedroom_devices/Air conditioner.png',
      'garage-door':
          'assets/images/room_devices/garage_devices/siding gate.png',
      'main-lock':
          'assets/images/room_devices/garage_devices/siding gate.png',
      'living-fan':
          'assets/images/room_devices/livingroom_devices/fan.png',
    };

    final exact = byId[device.id];
    if (exact != null) return exact;

    final idLower = device.id.toLowerCase();
    final nameLower = device.name.toLowerCase();

    // Nhận diện theo tên / ID cổng trượt hoặc cửa
    if (idLower.contains('gate') ||
        nameLower.contains('gate') ||
        idLower.contains('siding') ||
        nameLower.contains('siding') ||
        idLower.contains('sliding') ||
        nameLower.contains('sliding') ||
        nameLower.contains('cổng') ||
        nameLower.contains('cong')) {
      return 'assets/images/room_devices/garage_devices/siding gate.png';
    }

    // Nhận diện điều hoà
    if (idLower.contains('ac') ||
        nameLower.contains('ac') ||
        nameLower.contains('conditioner') ||
        nameLower.contains('điều hòa') ||
        nameLower.contains('dieu hoa')) {
      return 'assets/images/room_devices/bedroom_devices/Air conditioner.png';
    }

    // Nhận diện LED RGB
    if (device.type == DeviceType.ledRgb ||
        idLower.contains('rgb') ||
        nameLower.contains('rgb')) {
      return 'assets/images/room_devices/bedroom_devices/led rgb.png';
    }

    return _typeProductImage(device.type);
  }

  static String? _typeProductImage(DeviceType type) => switch (type) {
    DeviceType.light =>
      'assets/images/room_devices/livingroom_devices/pendant light.png',
    DeviceType.ledRgb =>
      'assets/images/room_devices/bedroom_devices/led rgb.png',
    DeviceType.thermostat =>
      'assets/images/room_devices/bedroom_devices/Air conditioner.png',
    DeviceType.fan =>
      'assets/images/room_devices/livingroom_devices/fan.png',
    DeviceType.lock =>
      'assets/images/room_devices/garage_devices/siding gate.png',
    _ => null,
  };


  /// Ảnh lớn làm background full-bleed cho màn device detail.
  static String? detailImage(Device device) {
    final idLower = device.id.toLowerCase();
    final nameLower = device.name.toLowerCase();
    if (idLower.contains('gate') ||
        nameLower.contains('gate') ||
        idLower.contains('siding') ||
        nameLower.contains('siding') ||
        idLower.contains('sliding') ||
        nameLower.contains('sliding') ||
        nameLower.contains('cổng') ||
        nameLower.contains('cong')) {
      return 'assets/images/devices/Gate.jpg';
    }

    return switch (device.type) {
      DeviceType.light || DeviceType.ledRgb => 'assets/images/devices/light.jpg',
      DeviceType.thermostat => 'assets/images/devices/Air Conditioner.jpg',
      DeviceType.fan => 'assets/images/devices/fan.jpg',
      DeviceType.lock => 'assets/images/devices/Gate.jpg',
      _ => null,
    };
  }


  /// Bỏ dấu tiếng Việt và chuẩn hoá về chữ thường không dấu.
  static String _stripDiacritics(String str) {
    const withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  /// Chuẩn hoá tên / slug / id phòng sang loại phòng chuẩn:
  /// 'living-room', 'bedroom', 'kitchen', 'garage', 'bathroom', 'garden'.
  /// Hỗ trợ cả tiếng Việt (có dấu / không dấu) và tiếng Anh:
  /// - Phòng khách / Living Room / phong-khach → 'living-room'
  /// - Phòng ngủ / Bedroom / phong-ngu → 'bedroom'
  /// - Phòng bếp / Nhà bếp / Bếp / Kitchen / phong-bep → 'kitchen'
  /// - Garage / Nhà xe / Gara → 'garage'
  /// - Phòng tắm / Nhà vệ sinh / Bathroom / WC → 'bathroom'
  /// - Sân vườn / Vườn / Garden / Ban công → 'garden'
  static String? canonicalRoomType(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final cleaned = input.trim().toLowerCase();

    // Khớp trực tiếp mã chuẩn
    switch (cleaned) {
      case 'living-room':
      case 'livingroom':
        return 'living-room';
      case 'bedroom':
        return 'bedroom';
      case 'kitchen':
        return 'kitchen';
      case 'garage':
        return 'garage';
      case 'bathroom':
        return 'bathroom';
      case 'garden':
        return 'garden';
    }

    final normalized = _stripDiacritics(cleaned);

    // Phòng khách / Living Room
    if (normalized.contains('khach') ||
        normalized.contains('living') ||
        normalized.contains('sinh hoat')) {
      return 'living-room';
    }

    // Phòng ngủ / Bedroom
    if (normalized.contains('ngu') || normalized.contains('bed')) {
      return 'bedroom';
    }

    // Bếp / Kitchen / Phòng ăn
    if (normalized.contains('bep') ||
        normalized.contains('kitchen') ||
        normalized.contains('dining') ||
        normalized.contains('nau an') ||
        normalized.contains('phong an') ||
        normalized.contains('nha an')) {
      return 'kitchen';
    }

    // Nhà vệ sinh / Phòng tắm / Bathroom
    if (normalized.contains('tam') ||
        normalized.contains('bath') ||
        normalized.contains('toilet') ||
        normalized.contains('wc') ||
        normalized.contains('ve sinh')) {
      return 'bathroom';
    }

    // Garage / Nhà xe / Bãi đỗ xe
    if (normalized.contains('garage') ||
        normalized.contains('gara') ||
        normalized.contains('nha xe') ||
        normalized.contains('bai xe') ||
        normalized.contains('do xe')) {
      return 'garage';
    }

    // Sân vườn / Garden / Ban công
    if (normalized.contains('vuon') ||
        normalized.contains('garden') ||
        normalized.contains('san') ||
        normalized.contains('balcony') ||
        normalized.contains('ban cong')) {
      return 'garden';
    }

    return null;
  }

  /// Ảnh nền phòng full-bleed (dọc) cho màn room device.
  static String? roomBackground(String roomIdOrName) {
    final type = canonicalRoomType(roomIdOrName);
    return switch (type) {
      'living-room' => 'assets/images/rooms/vertical_room/livingroom.png',
      'bedroom' => 'assets/images/rooms/vertical_room/bedroom.jpg',
      'kitchen' => 'assets/images/rooms/vertical_room/kitchen.jpg',
      'garage' => 'assets/images/rooms/vertical_room/garage.jpg',
      'bathroom' => 'assets/images/rooms/vertical_room/bathroom.jpg',
      'garden' => 'assets/images/rooms/vertical_room/garden.jpg',
      _ => null,
    };
  }

  /// Ảnh (ngang) cho card phòng ở màn Rooms overview.
  static String? roomCardImage(String roomIdOrName) {
    final type = canonicalRoomType(roomIdOrName);
    return switch (type) {
      'living-room' => 'assets/images/rooms/horizontal_room/livingroom.jpg',
      'bedroom' => 'assets/images/rooms/horizontal_room/bedroom.jpg',
      'kitchen' => 'assets/images/rooms/horizontal_room/kitchen.jpg',
      'garage' => 'assets/images/rooms/horizontal_room/garage.jpg',
      'bathroom' => 'assets/images/rooms/horizontal_room/bathroom.jpg',
      'garden' => 'assets/images/rooms/horizontal_room/garden.jpg',
      _ => null,
    };
  }
}

