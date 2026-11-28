import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../home/data/home_providers.dart';
import 'energy_repository.dart';
import 'models/energy_models.dart';

final energyRepositoryProvider = Provider<EnergyRepository>((ref) {
  final client = ref.watch(cloudApiClientProvider);
  return ApiEnergyRepository(
    client,
    getHomeId: () => ref.read(currentHomeIdProvider),
  );
});

final selectedEnergyPeriodProvider = StateProvider<String>((ref) => '30D');

final energyAnalyticsProvider = FutureProvider<EnergyAnalyticsModel>((
  ref,
) async {
  final repo = ref.watch(energyRepositoryProvider);
  final period = ref.watch(selectedEnergyPeriodProvider);
  final homeId = ref.watch(currentHomeIdProvider);

  return repo.getHomeEnergyAnalytics(homeId: homeId, period: period);
});

final demandResponseSettingsProvider =
    FutureProvider.autoDispose<DemandResponseSettingsModel>((ref) async {
      final repo = ref.watch(energyRepositoryProvider);
      final homeId = ref.watch(currentHomeIdProvider);
      return repo.getDemandResponseSettings(homeId: homeId);
    });
