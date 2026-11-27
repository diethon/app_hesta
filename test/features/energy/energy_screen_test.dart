import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/energy/data/energy_providers.dart';
import 'package:syna/features/energy/data/energy_repository.dart';
import 'package:syna/features/energy/data/models/energy_models.dart';
import 'package:syna/features/energy/presentation/energy_screen.dart';
import 'package:syna/l10n/app_localizations.dart';

class _FakeEnergyRepository implements EnergyRepository {
  DemandResponseSettingsModel _settings = const DemandResponseSettingsModel(
    homeId: 'home-test',
    enabled: true,
    peakThresholdWatts: 4000,
    mode: 'AUTO_SHED',
  );

  @override
  Future<EnergyAnalyticsModel> getHomeEnergyAnalytics({
    String? homeId,
    String period = '30D',
  }) async {
    // Return mock analytics directly for testing
    return ApiEnergyRepository.buildMockAnalytics(period);
  }

  @override
  Future<DemandResponseSettingsModel> getDemandResponseSettings({
    String? homeId,
  }) async {
    return _settings;
  }

  @override
  Future<DemandResponseSettingsModel> updateDemandResponseSettings({
    String? homeId,
    required DemandResponseSettingsModel settings,
  }) async {
    _settings = settings;
    return _settings;
  }

  @override
  Future<DemandResponseEvaluationModel> evaluateDemandResponse({
    String? homeId,
    double? simulatedWatts,
  }) async {
    final watts = simulatedWatts ?? 2400.0;
    final excess = (watts - _settings.peakThresholdWatts).clamp(
      0.0,
      double.infinity,
    );
    return DemandResponseEvaluationModel(
      totalCurrentWatts: watts,
      peakThresholdWatts: _settings.peakThresholdWatts,
      excessWatts: excess,
      status: excess > 0 ? 'PEAK_SHEDDING_EXECUTED' : 'NORMAL',
      sheddedDevices: excess > 0 ? const ['Smart LED RGB Strip'] : const [],
      wattsSaved: excess > 0 ? 1500 : 0,
      message: excess > 0
          ? 'Đã tự động cắt tải bảo vệ!'
          : 'Công suất trong ngưỡng an toàn.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EnergyScreen renders 3-period tabs and EVN KPI metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          energyRepositoryProvider.overrideWithValue(_FakeEnergyRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('vi'),
          home: EnergyScreen(),
        ),
      ),
    );

    // Initial pump to load data
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Tiêu Thụ Năng Lượng'), findsOneWidget);
    expect(
      find.text('Ước tính kWh & Tiền điện biểu giá EVN 6 bậc'),
      findsOneWidget,
    );

    // Verify 3 period segments
    expect(find.text('24 Giờ'), findsOneWidget);
    expect(find.text('7 Ngày'), findsOneWidget);
    expect(find.text('30 Ngày'), findsOneWidget);

    // Verify KPI cards
    expect(find.text('Tổng Điện Năng'), findsOneWidget);
    expect(find.text('Tiền Tạm Tính'), findsOneWidget);

    // Verify EVN Tier ladder card
    expect(find.text('Biểu Giá EVN 6 Bậc'), findsOneWidget);

    // Verify Device breakdown
    expect(find.text('Cơ Cấu Tiêu Thụ Thiết Bị'), findsOneWidget);

    // Tap on 7 Ngày segment
    await tester.tap(find.text('7 Ngày'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify 7 Ngày is active
    expect(find.text('Biểu Đồ Phụ Tải (7D)'), findsOneWidget);

    // Verify Demand Response (UC-ENG-03) and scroll button into viewport
    final testBtn = find.text('Thử 5.5 kW');
    await tester.ensureVisible(find.text('Cắt Tải Đỉnh (Peak Shaving)'));
    expect(find.text('Cắt Tải Đỉnh (Peak Shaving)'), findsOneWidget);
    expect(find.text('Lưu Hạn Mức'), findsOneWidget);

    await tester.ensureVisible(testBtn);
    await tester.pumpAndSettle();
    await tester.tap(testBtn);
    await tester.pumpAndSettle();

    expect(find.text('Đã tự động cắt tải bảo vệ!'), findsAtLeastNWidgets(1));
    expect(
      find.text('Công suất đo: 5500W / Ngưỡng: 4000W • Đã hạ: -1500W'),
      findsOneWidget,
    );
    expect(find.text('Smart LED RGB Strip'), findsOneWidget);
  });
}
