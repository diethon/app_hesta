enum AppPermission { camera, microphone, notification, localNetwork, biometric }

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

abstract interface class PermissionService {
  Future<AppPermissionStatus> status(AppPermission permission);

  Future<AppPermissionStatus> request(AppPermission permission);

  Future<bool> openSettings();
}

class DeferredPermissionService implements PermissionService {
  @override
  Future<AppPermissionStatus> status(AppPermission permission) async {
    return AppPermissionStatus.denied;
  }

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    return AppPermissionStatus.denied;
  }

  @override
  Future<bool> openSettings() async {
    return false;
  }
}
