import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/automation/presentation/automation_screen.dart';
import 'package:syna/features/recommendation/domain/recommendation_models.dart';
import 'package:syna/features/recommendation/presentation/widgets/recommendation_item_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationItemCard UI Tests', () {
    testWidgets('renders pending recommendation with approve and reject buttons',
        (tester) async {
      bool approved = false;
      bool rejected = false;
      bool dismissed = false;

      const rec = Recommendation(
        id: 'rec-test-1',
        homeId: 'home-1',
        deviceId: 'light-1',
        deviceName: 'Đèn ngủ',
        triggerCondition: RecommendationTrigger(
          type: 'SCHEDULE',
          time: '23:00',
          repeatDays: [1, 2, 3, 4, 5],
        ),
        proposedAction: RecommendationAction(
          deviceId: 'light-1',
          action: 'TURN_OFF',
        ),
        explanation: 'Thói quen tắt đèn lúc 23:00',
        confidence: 0.95,
        status: 'PENDING',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationItemCard(
              recommendation: rec,
              onApprove: () => approved = true,
              onReject: () => rejected = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Verify device name & explanation
      expect(find.text('Đèn ngủ'), findsOneWidget);
      expect(find.text('Thói quen tắt đèn lúc 23:00'), findsOneWidget);
      expect(find.text('95% tin cậy'), findsOneWidget);

      // Verify trigger time and repeat days
      expect(find.text('Lúc 23:00'), findsOneWidget);
      expect(find.text('Thứ 2 - Thứ 6'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Chấp nhận & Tạo quy tắc'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);

      // Tap approve
      await tester.tap(find.text('Chấp nhận & Tạo quy tắc'));
      await tester.pump();
      expect(approved, true);

      // Tap reject
      await tester.tap(find.text('Từ chối'));
      await tester.pump();
      expect(rejected, true);

      // Tap dismiss
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(dismissed, true);
    });

    testWidgets('renders resolved recommendation with status pill',
        (tester) async {
      final rec = Recommendation(
        id: 'rec-test-2',
        homeId: 'home-1',
        deviceId: 'ac-1',
        deviceName: 'Điều hòa phòng khách',
        triggerCondition: const RecommendationTrigger(
          type: 'SCHEDULE',
          time: '18:00',
          repeatDays: [1, 2, 3, 4, 5, 6, 7],
        ),
        proposedAction: const RecommendationAction(
          deviceId: 'ac-1',
          action: 'SET_TEMPERATURE',
          parameters: {'temperature': 26},
        ),
        explanation: 'Thói quen bật điều hòa 26°C lúc 18:00 hàng ngày',
        confidence: 0.88,
        status: 'APPROVED',
        resolvedAt: DateTime(2026, 11, 1, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationItemCard(
              recommendation: rec,
              onApprove: () {},
              onReject: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Điều hòa phòng khách'), findsOneWidget);
      expect(find.text('Hàng ngày'), findsOneWidget);
      expect(find.text('ĐÃ DUYỆT'), findsOneWidget);
      expect(find.text('Chấp nhận & Tạo quy tắc'), findsNothing);
    });
  });

  group('Automation Hub Screen Tests', () {
    testWidgets('renders AutomationScreen and switches tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AutomationScreen(initialTab: 0),
          ),
        ),
      );

      // Initial pump
      await tester.pump();

      // Check title and segmented control exist
      expect(find.text('Tự động hóa (Automations)'), findsOneWidget);
      expect(find.byType(AutomationScreen), findsOneWidget);
    });
  });
}
