class HomeDto {
  const HomeDto({
    required this.id,
    required this.name,
    this.role,
  });

  factory HomeDto.fromJson(Map<String, dynamic> json) {
    return HomeDto(
      id: (json['homeId'] ?? json['id'] ?? '').toString(),
      name: (json['homeName'] ?? json['name'] ?? 'Home').toString(),
      role: json['role'] as String?,
    );
  }

  final String id;
  final String name;
  final String? role;
}
