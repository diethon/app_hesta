import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syna/app/app.dart';
import 'package:syna/app/config/app_environment.dart';
import 'package:syna/app/config/providers.dart';
import 'package:syna/core/storage/token_storage.dart';
import 'package:syna/features/authentication/data/auth_providers.dart';
import 'package:syna/features/authentication/data/mock_auth_repository.dart';
import 'package:syna/features/devices/data/device_providers.dart';
import 'package:syna/features/devices/data/mock_device_repository.dart';

import 'support/in_memory_token_storage.dart';

void main() {
  testWidgets('renders login screen after onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final preferences = await SharedPreferences.getInstance();
    final tokenStorage = InMemoryTokenStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(AppEnvironment.development),
          sharedPreferencesProvider.overrideWithValue(preferences),
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(tokenStorage),
          ),
          deviceRepositoryProvider.overrideWithValue(MockDeviceRepository()),
        ],
        child: const SynaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}
