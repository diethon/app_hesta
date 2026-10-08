import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/authentication/data/mock_auth_repository.dart';
import 'package:syna/features/authentication/presentation/auth_controller.dart';
import 'package:syna/features/authentication/presentation/auth_state.dart';

import '../../support/in_memory_token_storage.dart';

void main() {
  test('login stores authenticated state', () async {
    final repository = MockAuthRepository(InMemoryTokenStorage());
    final controller = AuthController(repository);

    await controller.login('alex@syna.local', '123456');

    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.session?.email, 'alex@syna.local');
  });

  test('refresh token reuses stored refresh token', () async {
    final storage = InMemoryTokenStorage();
    final repository = MockAuthRepository(storage);

    final session = await repository.login(
      email: 'alex@syna.local',
      password: '123456',
    );
    final refreshed = await repository.refreshToken();

    expect(refreshed.refreshToken, session.refreshToken);
    expect(refreshed.accessToken, isNot(session.accessToken));
  });
}
