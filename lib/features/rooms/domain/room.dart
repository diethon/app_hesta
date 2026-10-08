class Room {
  const Room({
    required this.id,
    required this.name,
    required this.deviceCount,
    required this.activeCount,
    required this.temperature,
  });

  final String id;
  final String name;
  final int deviceCount;
  final int activeCount;
  final int temperature;

  /// Khoá tra cứu visuals (ảnh/màu/icon) suy từ tên phòng —
  /// id backend là UUID nên không dùng làm khoá được.
  /// 'Living Room' → 'living-room'.
  String get slug => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
}
