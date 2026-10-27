import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../home/data/home_providers.dart';
import '../domain/automation_models.dart';
import 'automation_repository.dart';

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  final client = ref.watch(cloudApiClientProvider);
  return AutomationRepository(client: client);
});

final automationRulesListProvider =
    AsyncNotifierProvider<AutomationRulesListNotifier, List<AutomationRule>>(
  AutomationRulesListNotifier.new,
);

class AutomationRulesListNotifier
    extends AsyncNotifier<List<AutomationRule>> {
  @override
  Future<List<AutomationRule>> build() async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null) {
      return _mockRules();
    }

    if (kUseMockData) {
      return _mockRules();
    }

    try {
      final repo = ref.read(automationRepositoryProvider);
      final rules = await repo.getRules(homeId);
      if (rules.isEmpty) {
        return _mockRules();
      }
      return rules;
    } catch (_) {
      return _mockRules();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final homeId = ref.read(currentHomeIdProvider);
      if (homeId == null) return _mockRules();
      final repo = ref.read(automationRepositoryProvider);
      return repo.getRules(homeId);
    });
  }

  Future<void> toggleRule(String ruleId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.indexWhere((r) => r.id == ruleId);
    if (index == -1) return;

    final target = current[index];
    final updated = target.copyWith(enabled: !target.enabled);

    state = AsyncValue.data([
      for (int i = 0; i < current.length; i++)
        if (i == index) updated else current[i],
    ]);

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(automationRepositoryProvider);
        await repo.setEnabled(homeId, ruleId, updated.enabled);
      } catch (_) {
        state = AsyncValue.data(current);
      }
    }
  }

  Future<void> deleteRule(String ruleId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((r) => r.id != ruleId).toList());

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(automationRepositoryProvider);
        await repo.deleteRule(homeId, ruleId);
      } catch (_) {
        state = AsyncValue.data(current);
      }
    }
  }

  List<AutomationRule> _mockRules() {
    return const [
      AutomationRule(
        id: 'rule-sunset',
        homeId: 'home-default',
        name: 'Hoàng hôn (Sunset Routine)',
        description: 'Tự động đóng rèm phòng khách và bật đèn khi mặt trời lặn',
        triggerType: 'SCHEDULE',
        enabled: true,
        conditions: [
          RuleCondition(
            attribute: 'time',
            operator: 'EQ',
            expectedValue: '18:00',
          ),
        ],
        actions: [
          RuleAction(
            deviceId: 'living-curtain',
            deviceName: 'Rèm phòng khách',
            action: 'CLOSE',
          ),
        ],
      ),
      AutomationRule(
        id: 'rule-night-motion',
        homeId: 'home-default',
        name: 'Cảm biến chuyển động ban đêm',
        description: 'Phát hiện chuyển động ở hành lang từ 23:00 - 05:00 bật đèn 30%',
        triggerType: 'SENSOR',
        enabled: true,
        conditions: [
          RuleCondition(
            deviceId: 'hallway-motion',
            deviceName: 'Cảm biến hành lang',
            attribute: 'motion',
            operator: 'EQ',
            expectedValue: true,
          ),
        ],
        actions: [
          RuleAction(
            deviceId: 'hallway-light',
            deviceName: 'Đèn hành lang',
            action: 'SET_BRIGHTNESS',
            parameters: {'brightness': 30},
          ),
        ],
      ),
      AutomationRule(
        id: 'rule-temperature-alert',
        homeId: 'home-default',
        name: 'Bảo vệ quá nhiệt phòng khách',
        description: 'Khi nhiệt độ phòng > 30°C tự động bật điều hòa 24°C',
        triggerType: 'SENSOR',
        enabled: false,
        conditions: [
          RuleCondition(
            deviceId: 'living-temp-sensor',
            deviceName: 'Cảm biến nhiệt độ',
            attribute: 'temperature',
            operator: 'GT',
            expectedValue: 30,
          ),
        ],
        actions: [
          RuleAction(
            deviceId: 'living-ac',
            deviceName: 'Điều hòa phòng khách',
            action: 'SET_TEMPERATURE',
            parameters: {'temperature': 24},
          ),
        ],
      ),
    ];
  }
}

final automationRuleExecutionsProvider =
    FutureProvider.family.autoDispose<List<AutomationExecution>, String>(
  (ref, ruleId) async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null || kUseMockData) {
      return [
        AutomationExecution(
          id: 'exec-auto-1',
          ruleId: ruleId,
          status: 'SUCCESS',
          executedAt: DateTime.now().subtract(const Duration(minutes: 45)),
          durationMs: 120,
          details: 'Tất cả điều kiện thỏa mãn, đã kích hoạt hành động thành công',
        ),
        AutomationExecution(
          id: 'exec-auto-2',
          ruleId: ruleId,
          status: 'SUCCESS',
          executedAt: DateTime.now().subtract(const Duration(hours: 12)),
          durationMs: 110,
          details: 'Kích hoạt định kỳ thành công',
        ),
      ];
    }

    try {
      final repo = ref.read(automationRepositoryProvider);
      return await repo.getExecutions(homeId, ruleId);
    } catch (_) {
      return [];
    }
  },
);
