import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage() {
    api = HestaApi(accessToken: () => _accessToken, onUnauthorized: signOut);
  }

  final FlutterSecureStorage _storage;
  late final HestaApi api;
  HestaUser? _user;
  String? _accessToken;
  bool _ready = false;

  HestaUser? get user => _user;
  bool get ready => _ready;

  Future<void> restore() async {
    try {
      final values = await Future.wait([
        _storage.read(key: 'accessToken'),
        _storage.read(key: 'userInfo'),
      ]);
      if (values[0] != null && values[1] != null) {
        final parsed = asMap(jsonDecode(values[1]!));
        if (asText(parsed['id']).isNotEmpty && asText(parsed['email']).isNotEmpty) {
          _accessToken = values[0];
          _user = HestaUser.fromJson(parsed);
        }
      }
    } catch (_) {
      _accessToken = null;
      _user = null;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    final result = await api.login(email, password);
    final token = asText(result['accessToken']);
    final user = HestaUser.fromJson(asMap(result['user']));
    if (token.isEmpty || user.id.isEmpty) throw const ApiException('Dữ liệu đăng nhập không hợp lệ.');
    await _storage.write(key: 'accessToken', value: token);
    await _storage.write(key: 'userInfo', value: jsonEncode(user.toJson()));
    _accessToken = token;
    _user = user;
    notifyListeners();
  }

  Future<void> updateUser(HestaUser user) async {
    await _storage.write(key: 'userInfo', value: jsonEncode(user.toJson()));
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    _accessToken = null;
    _user = null;
    notifyListeners();
    await Future.wait([
      _storage.delete(key: 'accessToken'),
      _storage.delete(key: 'userInfo'),
    ]);
  }
}
