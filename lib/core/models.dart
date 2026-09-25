typedef JsonMap = Map<String, dynamic>;

JsonMap asMap(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

String asText(Object? value) => value?.toString() ?? '';

List<JsonMap> asMapList(Object? value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];

class HestaUser {
  const HestaUser({required this.id, required this.fullName, required this.email, required this.platformRole, this.phoneNumber, this.avatarUrl});

  final String id;
  final String fullName;
  final String email;
  final String platformRole;
  final String? phoneNumber;
  final String? avatarUrl;

  factory HestaUser.fromJson(JsonMap json) => HestaUser(
    id: asText(json['id']),
    fullName: asText(json['fullName']),
    email: asText(json['email']),
    platformRole: asText(json['platformRole']),
    phoneNumber: json['phoneNumber'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );

  JsonMap toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'platformRole': platformRole,
    'phoneNumber': phoneNumber,
    'avatarUrl': avatarUrl,
  };
}

class HomeSummary {
  const HomeSummary({required this.id, required this.name, required this.role});
  final String id;
  final String name;
  final String role;
  bool get isOwner => role == 'OWNER';

  factory HomeSummary.fromJson(JsonMap json) => HomeSummary(
    id: asText(json['homeId']),
    name: asText(json['homeName']),
    role: asText(json['role']),
  );
}

class Room {
  const Room({required this.id, required this.name});
  final String id;
  final String name;
  factory Room.fromJson(JsonMap json) => Room(id: asText(json['id']), name: asText(json['name']));
}

class Device {
  const Device({required this.id, required this.name, required this.type, required this.status, required this.state, this.roomId, this.roomName, this.lastSeen});
  final String id;
  final String name;
  final String type;
  final String status;
  final JsonMap state;
  final String? roomId;
  final String? roomName;
  final String? lastSeen;
  bool get isOnline => status == 'ONLINE';

  factory Device.fromJson(JsonMap json) => Device(
    id: asText(json['id']),
    name: asText(json['name']),
    type: asText(json['deviceType']),
    status: asText(json['status']),
    state: asMap(json['currentState']),
    roomId: json['roomId'] as String?,
    roomName: json['roomName'] as String?,
    lastSeen: json['lastSeen'] as String?,
  );
}

class HomeScene {
  const HomeScene({required this.id, required this.name, required this.enabled, required this.actionCount, this.description});
  final String id;
  final String name;
  final bool enabled;
  final int actionCount;
  final String? description;

  factory HomeScene.fromJson(JsonMap json) => HomeScene(
    id: asText(json['id']),
    name: asText(json['name']),
    enabled: json['enabled'] == true,
    actionCount: json['actions'] is List ? (json['actions'] as List).length : 0,
    description: json['description'] as String?,
  );
}

class HomeMember {
  const HomeMember({required this.id, required this.name, required this.email, required this.role});
  final String id;
  final String name;
  final String email;
  final String role;
  factory HomeMember.fromJson(JsonMap json) => HomeMember(
    id: asText(json['id']),
    name: asText(json['fullName']),
    email: asText(json['email']),
    role: asText(json['role']),
  );
}
