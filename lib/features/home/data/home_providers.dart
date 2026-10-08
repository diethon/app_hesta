import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart';
import '../../authentication/presentation/auth_controller.dart';
import 'models/home_dto.dart';

final myHomesProvider = FutureProvider.autoDispose<List<HomeDto>>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null || kUseMockData) {
    return const [];
  }

  final client = ref.watch(cloudApiClientProvider);
  final response = await client.get<dynamic>('/api/v1/homes/my-homes');
  final body = response.data;
  final result = body is Map
      ? (body['result'] ?? body['data'])
      : (body is List ? body : null);

  if (result is List && result.isNotEmpty) {
    return result
        .whereType<Map>()
        .map((m) => HomeDto.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  // Nếu người dùng mới chưa có nhà, tự động tạo nhà mặc định trên backend_hesta
  try {
    final createRes = await client.post<Map<String, dynamic>>(
      '/api/v1/homes',
      data: {'name': 'Nhà của ${session.name}'},
    );
    final createResult = createRes.data?['result'];
    if (createResult is Map<String, dynamic>) {
      return [HomeDto.fromJson(createResult)];
    }
  } catch (_) {}

  return const [];
});

final currentHomeIdProvider = Provider.autoDispose<String?>((ref) {
  final homes = ref.watch(myHomesProvider).valueOrNull;
  if (homes != null && homes.isNotEmpty) {
    return homes.first.id;
  }
  return null;
});
