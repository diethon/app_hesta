import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/automation/data/automation_providers.dart';
import 'package:syna/features/automation/domain/automation_models.dart';
import 'package:syna/features/automation/presentation/automation_rules_screen.dart';
import 'package:syna/features/recommendation/data/recommendation_providers.dart';
import 'package:syna/features/recommendation/domain/recommendation_models.dart';
import 'package:syna/features/recommendation/presentation/recommendations_screen.dart';
import 'package:syna/features/scene/data/scene_providers.dart';
import 'package:syna/features/scene/domain/scene.dart';
import 'package:syna/features/scene/presentation/scene_icons.dart';
import 'package:syna/features/scene/presentation/scenes_screen.dart';

class _MockScenesNotifier extends ScenesListNotifier {
  _MockScenesNotifier(this.scenes);
  final List<Scene> scenes;
  @override
  Future<List<Scene>> build() async => scenes;
}

class _MockRulesNotifier extends AutomationRulesListNotifier {
  _MockRulesNotifier(this.rules);
  final List<AutomationRule> rules;
  @override
  Future<List<AutomationRule>> build() async => rules;
}

class _MockRecsNotifier extends RecommendationsListNotifier {
  _MockRecsNotifier(this.recs);
  final List<Recommendation> recs;
  @override
  Future<List<Recommendation>> build() async => recs;
}

class _MockMlStatusNotifier extends MlModelStatusNotifier {
  _MockMlStatusNotifier(this.status);
  final MlModelStatus status;
  @override
  Future<MlModelStatus> build() async => status;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SceneAtmosphere Unit Tests', () {
    test('returns correct atmosphere for sun/morning', () {
      final atm = SceneIcons.getAtmosphere('sun');
      expect(atm.vietnameseLabel, 'Buổi sáng');
      expect(atm.icon, Icons.wb_sunny_rounded);
    });

    test('returns correct atmosphere for movie/tv', () {
      final atm = SceneIcons.getAtmosphere('movie');
      expect(atm.vietnameseLabel, 'Xem phim');
      expect(atm.icon, Icons.movie_rounded);
    });

    test('returns default atmosphere for unknown icon', () {
      final atm = SceneIcons.getAtmosphere('non_existent');
      expect(atm.vietnameseLabel, 'Ngữ cảnh');
    });
  });

  group('Redesigned Screens Widget Rendering', () {
    testWidgets('ScenesScreen renders quick scene strip and scene items',
        (tester) async {
      final sampleScenes = [
        const Scene(
          id: 'sc-1',
          homeId: 'home-1',
          name: 'Chào buổi sáng',
          icon: 'sun',
          description: 'Mở rèm và bật máy pha cà phê',
          enabled: true,
          actions: [
            SceneAction(
              id: 'act-1',
              targetDeviceId: 'curtain-1',
              targetDeviceName: 'Rèm phòng khách',
              action: 'OPEN',
              order: 0,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scenesListProvider.overrideWith(() => _MockScenesNotifier(sampleScenes)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ScenesScreen(isEmbedded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('KÍCH HOẠT NHANH 1-CHẠM'), findsOneWidget);
      expect(find.text('Chào buổi sáng'), findsAtLeastNWidgets(1));
      expect(find.text('1 thiết bị'), findsOneWidget);
      expect(find.text('Chạy ngay'), findsOneWidget);
    });

    testWidgets('AutomationRulesScreen renders visual IF/THEN recipe card',
        (tester) async {
      const sampleRule = AutomationRule(
        id: 'rule-1',
        homeId: 'home-1',
        name: 'Tự động bật điều hòa khi nóng',
        description: 'Bật máy lạnh khi nhiệt độ vượt 28 độ C',
        triggerType: 'SENSOR',
        enabled: true,
        conditions: [
          RuleCondition(
            deviceName: 'Cảm biến nhiệt độ',
            attribute: 'temperature',
            operator: 'GT',
            expectedValue: 28,
          ),
        ],
        actions: [
          RuleAction(
            deviceName: 'Điều hòa phòng khách',
            action: 'TURN_ON',
            parameters: {'temperature': 24},
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            automationRulesListProvider
                .overrideWith(() => _MockRulesNotifier([sampleRule])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AutomationRulesScreen(isEmbedded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tự động bật điều hòa khi nóng'), findsOneWidget);
      expect(find.text('KHI (IF)'), findsOneWidget);
      expect(find.text('THÌ (THEN)'), findsOneWidget);
      expect(find.text('CẢM BIẾN'), findsAtLeastNWidgets(1));
    });

    testWidgets('RecommendationsScreen renders ML model card and scan action',
        (tester) async {
      const sampleRec = Recommendation(
        id: 'rec-1',
        homeId: 'home-1',
        deviceName: 'Đèn ban công',
        triggerCondition: RecommendationTrigger(
          type: 'SCHEDULE',
          time: '18:30',
          repeatDays: [1, 2, 3, 4, 5, 6, 7],
        ),
        proposedAction: RecommendationAction(
          deviceId: 'light-balcony',
          action: 'TURN_ON',
        ),
        explanation: 'Thói quen bật đèn ban công khi trời tối lúc 18:30',
        confidence: 0.92,
        status: 'PENDING',
      );

      const sampleMlStatus = MlModelStatus(
        status: 'READY',
        version: '2.1.0',
        accuracy: 0.94,
        trainSamples: 1500,
        confidenceThreshold: 0.8,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recommendationsListProvider
                .overrideWith(() => _MockRecsNotifier([sampleRec])),
            mlModelStatusProvider
                .overrideWith(() => _MockMlStatusNotifier(sampleMlStatus)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RecommendationsScreen(isEmbedded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mô hình AI & Machine Learning'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('Phân tích hành vi & Quét đề xuất mới'), findsOneWidget);
      expect(find.text('Đèn ban công'), findsOneWidget);
      expect(find.text('92% tin cậy'), findsOneWidget);
    });
  });
}
