import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('vi'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'Syna'**
  String get appName;

  /// No description provided for @welcomeBack.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều khiển ngôi nhà của bạn một cách dễ dàng'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @createAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get createAccount;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @needAssistance.
  ///
  /// In vi, this message translates to:
  /// **'Cần hỗ trợ?'**
  String get needAssistance;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Nhà'**
  String get home;

  /// No description provided for @rooms.
  ///
  /// In vi, this message translates to:
  /// **'Phòng'**
  String get rooms;

  /// No description provided for @automation.
  ///
  /// In vi, this message translates to:
  /// **'Tự động'**
  String get automation;

  /// No description provided for @assistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý'**
  String get assistant;

  /// No description provided for @energy.
  ///
  /// In vi, this message translates to:
  /// **'Điện năng'**
  String get energy;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @goodMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng, {name}'**
  String goodMorning(String name);

  /// No description provided for @everythingSecure.
  ///
  /// In vi, this message translates to:
  /// **'Mọi thứ an toàn'**
  String get everythingSecure;

  /// No description provided for @activeDevices.
  ///
  /// In vi, this message translates to:
  /// **'{count} thiết bị đang hoạt động'**
  String activeDevices(int count);

  /// No description provided for @quickScenes.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ cảnh nhanh'**
  String get quickScenes;

  /// No description provided for @favoriteDevices.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị yêu thích'**
  String get favoriteDevices;

  /// No description provided for @recentActivity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động gần đây'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get viewAll;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải'**
  String get loading;

  /// No description provided for @emptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get emptyTitle;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @offline.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến, hiển thị dữ liệu cache'**
  String get offline;

  /// No description provided for @localMode.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối Edge'**
  String get localMode;

  /// No description provided for @cloudMode.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối Cloud'**
  String get cloudMode;

  /// No description provided for @deviceDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thiết bị'**
  String get deviceDetail;

  /// No description provided for @camera.
  ///
  /// In vi, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @deleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccount;

  /// No description provided for @onboardingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Syna kết nối ngôi nhà thông minh Edge-first'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên thiết bị nội bộ khi có Wi-Fi LAN và tự chuyển sang cloud khi cần.'**
  String get onboardingSubtitle;

  /// No description provided for @continueAction.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continueAction;

  /// No description provided for @quickAccess.
  ///
  /// In vi, this message translates to:
  /// **'Truy cập nhanh'**
  String get quickAccess;

  /// No description provided for @automations.
  ///
  /// In vi, this message translates to:
  /// **'Tự động hoá'**
  String get automations;

  /// No description provided for @automationsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Kịch bản & quy tắc'**
  String get automationsSubtitle;

  /// No description provided for @cameraSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem trực tiếp'**
  String get cameraSubtitle;

  /// No description provided for @homeSecure.
  ///
  /// In vi, this message translates to:
  /// **'Nhà an toàn'**
  String get homeSecure;

  /// No description provided for @homeSecureSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mọi hệ thống hoạt động bình thường'**
  String get homeSecureSubtitle;

  /// No description provided for @homeAttention.
  ///
  /// In vi, this message translates to:
  /// **'Cần chú ý'**
  String get homeAttention;

  /// No description provided for @homeAttentionSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Có cửa chưa khoá, hãy kiểm tra'**
  String get homeAttentionSubtitle;

  /// No description provided for @doorsOpen.
  ///
  /// In vi, this message translates to:
  /// **'cửa mở'**
  String get doorsOpen;

  /// No description provided for @lightsOn.
  ///
  /// In vi, this message translates to:
  /// **'đèn bật'**
  String get lightsOn;

  /// No description provided for @systemArmed.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã kích hoạt'**
  String get systemArmed;

  /// No description provided for @systemDisarmed.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống chưa kích hoạt'**
  String get systemDisarmed;

  /// No description provided for @sceneAllOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt hết'**
  String get sceneAllOff;

  /// No description provided for @sceneArriveHome.
  ///
  /// In vi, this message translates to:
  /// **'Về nhà'**
  String get sceneArriveHome;

  /// No description provided for @sceneMovieNight.
  ///
  /// In vi, this message translates to:
  /// **'Xem phim'**
  String get sceneMovieNight;

  /// No description provided for @sceneGoodNight.
  ///
  /// In vi, this message translates to:
  /// **'Ngủ ngon'**
  String get sceneGoodNight;

  /// No description provided for @sceneAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngữ cảnh'**
  String get sceneAdd;

  /// No description provided for @locked.
  ///
  /// In vi, this message translates to:
  /// **'Đã khoá'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa khoá'**
  String get unlocked;

  /// No description provided for @secured.
  ///
  /// In vi, this message translates to:
  /// **'An toàn'**
  String get secured;

  /// No description provided for @deviceOn.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get deviceOn;

  /// No description provided for @deviceOff.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get deviceOff;

  /// No description provided for @deviceOnline.
  ///
  /// In vi, this message translates to:
  /// **'Trực tuyến'**
  String get deviceOnline;

  /// No description provided for @deviceOffline.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến'**
  String get deviceOffline;

  /// No description provided for @activityArrived.
  ///
  /// In vi, this message translates to:
  /// **'Alex đã về nhà'**
  String get activityArrived;

  /// No description provided for @activityMorningRoutine.
  ///
  /// In vi, this message translates to:
  /// **'Kích hoạt kịch bản buổi sáng'**
  String get activityMorningRoutine;

  /// No description provided for @activityPatioMotion.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện chuyển động ở sân'**
  String get activityPatioMotion;

  /// No description provided for @yourRooms.
  ///
  /// In vi, this message translates to:
  /// **'Phòng của bạn'**
  String get yourRooms;

  /// No description provided for @totalDevicesConnected.
  ///
  /// In vi, this message translates to:
  /// **'{count} thiết bị đã kết nối'**
  String totalDevicesConnected(int count);

  /// No description provided for @securityCameras.
  ///
  /// In vi, this message translates to:
  /// **'Camera an ninh'**
  String get securityCameras;

  /// No description provided for @camerasLive.
  ///
  /// In vi, this message translates to:
  /// **'Đang phát trực tiếp'**
  String get camerasLive;

  /// No description provided for @roomDevicesSummary.
  ///
  /// In vi, this message translates to:
  /// **'{count} thiết bị • {active} đang bật'**
  String roomDevicesSummary(int count, int active);

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// No description provided for @filterLighting.
  ///
  /// In vi, this message translates to:
  /// **'Chiếu sáng'**
  String get filterLighting;

  /// No description provided for @filterElectric.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị điện'**
  String get filterElectric;

  /// No description provided for @filterSensors.
  ///
  /// In vi, this message translates to:
  /// **'Cảm biến'**
  String get filterSensors;

  /// No description provided for @filterOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get filterOther;

  /// No description provided for @battery.
  ///
  /// In vi, this message translates to:
  /// **'Pin'**
  String get battery;

  /// No description provided for @colorTempWarm.
  ///
  /// In vi, this message translates to:
  /// **'Ấm'**
  String get colorTempWarm;

  /// No description provided for @colorTempNeutral.
  ///
  /// In vi, this message translates to:
  /// **'Trung tính'**
  String get colorTempNeutral;

  /// No description provided for @colorTempCold.
  ///
  /// In vi, this message translates to:
  /// **'Lạnh'**
  String get colorTempCold;

  /// No description provided for @slideToUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Kéo để mở khoá'**
  String get slideToUnlock;

  /// No description provided for @slideToLock.
  ///
  /// In vi, this message translates to:
  /// **'Kéo để khoá'**
  String get slideToLock;

  /// No description provided for @lockTempCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã tạm thời'**
  String get lockTempCode;

  /// No description provided for @lockMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get lockMembers;

  /// No description provided for @lockScenes.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ cảnh'**
  String get lockScenes;

  /// No description provided for @lockHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử mở khoá'**
  String get lockHistory;

  /// No description provided for @lockHistoryFingerprint.
  ///
  /// In vi, this message translates to:
  /// **'Mở bằng vân tay'**
  String get lockHistoryFingerprint;

  /// No description provided for @lockHistoryKeypad.
  ///
  /// In vi, this message translates to:
  /// **'Mở bằng mã số'**
  String get lockHistoryKeypad;

  /// No description provided for @lockHistoryApp.
  ///
  /// In vi, this message translates to:
  /// **'Mở từ ứng dụng'**
  String get lockHistoryApp;

  /// No description provided for @schedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch trình'**
  String get schedule;

  /// No description provided for @scheduleOnTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ bật'**
  String get scheduleOnTime;

  /// No description provided for @scheduleOffTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ tắt'**
  String get scheduleOffTime;

  /// No description provided for @usageHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử sử dụng'**
  String get usageHistory;

  /// No description provided for @fanAuto.
  ///
  /// In vi, this message translates to:
  /// **'Tự động'**
  String get fanAuto;

  /// No description provided for @fanLow.
  ///
  /// In vi, this message translates to:
  /// **'Thấp'**
  String get fanLow;

  /// No description provided for @fanMedium.
  ///
  /// In vi, this message translates to:
  /// **'Vừa'**
  String get fanMedium;

  /// No description provided for @fanHigh.
  ///
  /// In vi, this message translates to:
  /// **'Cao'**
  String get fanHigh;

  /// No description provided for @volume.
  ///
  /// In vi, this message translates to:
  /// **'Âm lượng'**
  String get volume;

  /// No description provided for @management.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý'**
  String get management;

  /// No description provided for @createNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mới'**
  String get createNew;

  /// No description provided for @triggerOccurs.
  ///
  /// In vi, this message translates to:
  /// **'Khi điều kiện xảy ra'**
  String get triggerOccurs;

  /// No description provided for @executeAction.
  ///
  /// In vi, this message translates to:
  /// **'Thực hiện hành động'**
  String get executeAction;

  /// No description provided for @triggerTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get triggerTime;

  /// No description provided for @triggerLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get triggerLocation;

  /// No description provided for @triggerDeviceState.
  ///
  /// In vi, this message translates to:
  /// **'Cảm biến'**
  String get triggerDeviceState;

  /// No description provided for @actionScenes.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ cảnh'**
  String get actionScenes;

  /// No description provided for @actionControlDevice.
  ///
  /// In vi, this message translates to:
  /// **'Điều khiển thiết bị'**
  String get actionControlDevice;

  /// No description provided for @activeRules.
  ///
  /// In vi, this message translates to:
  /// **'Quy tắc đang chạy'**
  String get activeRules;

  /// No description provided for @noAutomationsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quy tắc nào. Tạo quy tắc đầu tiên để ngôi nhà tự vận hành.'**
  String get noAutomationsYet;

  /// No description provided for @newScene.
  ///
  /// In vi, this message translates to:
  /// **'Ngữ cảnh mới'**
  String get newScene;

  /// No description provided for @devicesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thiết bị'**
  String devicesCount(int count);

  /// No description provided for @statusActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy'**
  String get statusActive;

  /// No description provided for @snapshot.
  ///
  /// In vi, this message translates to:
  /// **'Chụp'**
  String get snapshot;

  /// No description provided for @record.
  ///
  /// In vi, this message translates to:
  /// **'Ghi hình'**
  String get record;

  /// No description provided for @talk.
  ///
  /// In vi, this message translates to:
  /// **'Đàm thoại'**
  String get talk;

  /// No description provided for @spotlight.
  ///
  /// In vi, this message translates to:
  /// **'Đèn'**
  String get spotlight;

  /// No description provided for @cameraEvents.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện'**
  String get cameraEvents;

  /// No description provided for @energyUsage.
  ///
  /// In vi, this message translates to:
  /// **'Điện năng tiêu thụ'**
  String get energyUsage;

  /// No description provided for @energySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giám sát tiêu thụ theo thời gian thực'**
  String get energySubtitle;

  /// No description provided for @periodDaily.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get periodDaily;

  /// No description provided for @periodWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get periodMonthly;

  /// No description provided for @consumptionOverTime.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu thụ theo thời gian'**
  String get consumptionOverTime;

  /// No description provided for @consumption.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu thụ'**
  String get consumption;

  /// No description provided for @deviceDistribution.
  ///
  /// In vi, this message translates to:
  /// **'Phân bổ theo thiết bị'**
  String get deviceDistribution;

  /// No description provided for @categoryClimate.
  ///
  /// In vi, this message translates to:
  /// **'Điều hoà không khí'**
  String get categoryClimate;

  /// No description provided for @categoryRefrigeration.
  ///
  /// In vi, this message translates to:
  /// **'Tủ lạnh'**
  String get categoryRefrigeration;

  /// No description provided for @categoryLighting.
  ///
  /// In vi, this message translates to:
  /// **'Chiếu sáng'**
  String get categoryLighting;

  /// No description provided for @categoryOthers.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get categoryOthers;

  /// No description provided for @efficiencyTip.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo tiết kiệm'**
  String get efficiencyTip;

  /// No description provided for @efficiencyTipBody.
  ///
  /// In vi, this message translates to:
  /// **'Giảm điều hoà 2°C có thể tiết kiệm 12\$ trong tháng này.'**
  String get efficiencyTipBody;

  /// No description provided for @totalUsage.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiêu thụ'**
  String get totalUsage;

  /// No description provided for @estimatedCost.
  ///
  /// In vi, this message translates to:
  /// **'Chi phí ước tính'**
  String get estimatedCost;

  /// No description provided for @carbonFootprint.
  ///
  /// In vi, this message translates to:
  /// **'Dấu chân carbon'**
  String get carbonFootprint;

  /// No description provided for @assistantTitle.
  ///
  /// In vi, this message translates to:
  /// **'Syna AI'**
  String get assistantTitle;

  /// No description provided for @assistantOnline.
  ///
  /// In vi, this message translates to:
  /// **'Trực tuyến • Sẵn sàng'**
  String get assistantOnline;

  /// No description provided for @askAnything.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi Syna bất cứ điều gì...'**
  String get askAnything;

  /// No description provided for @suggestionEveningScene.
  ///
  /// In vi, this message translates to:
  /// **'Bật ngữ cảnh buổi tối'**
  String get suggestionEveningScene;

  /// No description provided for @suggestionLowerAc.
  ///
  /// In vi, this message translates to:
  /// **'Giảm nhiệt độ điều hoà'**
  String get suggestionLowerAc;

  /// No description provided for @suggestionLockDoor.
  ///
  /// In vi, this message translates to:
  /// **'Khoá cửa trước'**
  String get suggestionLockDoor;

  /// No description provided for @suggestionEnergyReport.
  ///
  /// In vi, this message translates to:
  /// **'Xem báo cáo điện năng'**
  String get suggestionEnergyReport;

  /// No description provided for @groupAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get groupAccount;

  /// No description provided for @groupSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật'**
  String get groupSecurity;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @languageName.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageName;

  /// No description provided for @privacy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get privacy;

  /// No description provided for @securitySettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt bảo mật'**
  String get securitySettings;

  /// No description provided for @homeMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên nhà'**
  String get homeMember;

  /// No description provided for @markAllRead.
  ///
  /// In vi, this message translates to:
  /// **'Đọc tất cả'**
  String get markAllRead;

  /// No description provided for @securityAlerts.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo an ninh'**
  String get securityAlerts;

  /// No description provided for @deviceAlerts.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo thiết bị'**
  String get deviceAlerts;

  /// No description provided for @completedAutomations.
  ///
  /// In vi, this message translates to:
  /// **'Tự động hoá đã chạy'**
  String get completedAutomations;

  /// No description provided for @tagAlert.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get tagAlert;

  /// No description provided for @tagWarning.
  ///
  /// In vi, this message translates to:
  /// **'Chú ý'**
  String get tagWarning;

  /// No description provided for @tagLowBattery.
  ///
  /// In vi, this message translates to:
  /// **'Pin yếu'**
  String get tagLowBattery;

  /// No description provided for @tagOffline.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến'**
  String get tagOffline;

  /// No description provided for @tagAutomation.
  ///
  /// In vi, this message translates to:
  /// **'Tự động hoá'**
  String get tagAutomation;

  /// No description provided for @notifPatioMotion.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện chuyển động ở sân'**
  String get notifPatioMotion;

  /// No description provided for @notifDoorUnlocked.
  ///
  /// In vi, this message translates to:
  /// **'Cửa chưa được khoá'**
  String get notifDoorUnlocked;

  /// No description provided for @notifBatteryLow.
  ///
  /// In vi, this message translates to:
  /// **'Quạt văn phòng sắp hết pin'**
  String get notifBatteryLow;

  /// No description provided for @notifDeviceOffline.
  ///
  /// In vi, this message translates to:
  /// **'Quạt văn phòng mất kết nối'**
  String get notifDeviceOffline;

  /// No description provided for @notifMorningRoutine.
  ///
  /// In vi, this message translates to:
  /// **'Đã kích hoạt kịch bản buổi sáng'**
  String get notifMorningRoutine;

  /// No description provided for @notifArriveHome.
  ///
  /// In vi, this message translates to:
  /// **'Đã kích hoạt ngữ cảnh Về nhà'**
  String get notifArriveHome;

  /// No description provided for @notifGoodNight.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất ngữ cảnh Ngủ ngon'**
  String get notifGoodNight;

  /// No description provided for @edgeFirstTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên backend Edge nội bộ'**
  String get edgeFirstTitle;

  /// No description provided for @edgeFirstSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thiết bị Edge trong mạng LAN trước, cloud khi cần'**
  String get edgeFirstSubtitle;

  /// No description provided for @privacyAndData.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư và dữ liệu'**
  String get privacyAndData;

  /// No description provided for @privacyAndDataSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ xoá tài khoản và xoá dữ liệu cục bộ'**
  String get privacyAndDataSubtitle;

  /// No description provided for @splashTagline.
  ///
  /// In vi, this message translates to:
  /// **'Atmospheric Intelligence'**
  String get splashTagline;

  /// No description provided for @onboarding1Title.
  ///
  /// In vi, this message translates to:
  /// **'Điều khiển thế giới của bạn.'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Trải nghiệm cuộc sống tương lai với tự động hoá liền mạch và AI thấu hiểu.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In vi, this message translates to:
  /// **'Tự động hoá thông minh.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Syna học thói quen của bạn để tự điều chỉnh ánh sáng, nhiệt độ và âm thanh.'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In vi, this message translates to:
  /// **'An ninh toàn diện.'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'An tâm với giám sát AI giữ ngôi nhà của bạn an toàn và riêng tư mọi lúc.'**
  String get onboarding3Subtitle;

  /// No description provided for @completeSetup.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất thiết lập'**
  String get completeSetup;

  /// No description provided for @getStarted.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get getStarted;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get alreadyHaveAccount;

  /// No description provided for @termsFooter.
  ///
  /// In vi, this message translates to:
  /// **'Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Quyền riêng tư của Syna.'**
  String get termsFooter;

  /// No description provided for @orContinueWith.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc tiếp tục với'**
  String get orContinueWith;

  /// No description provided for @signInWithFaceId.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng FaceID'**
  String get signInWithFaceId;

  /// No description provided for @newToApp.
  ///
  /// In vi, this message translates to:
  /// **'Lần đầu dùng Syna?'**
  String get newToApp;

  /// No description provided for @joinApp.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia Syna'**
  String get joinApp;

  /// No description provided for @registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản để bắt đầu quản lý không gian thông minh của bạn.'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get confirmPassword;

  /// No description provided for @agreeToTerms.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư.'**
  String get agreeToTerms;

  /// No description provided for @alreadyHaveAccountShort.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản?'**
  String get alreadyHaveAccountShort;

  /// No description provided for @assistantGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào! Mình là Syna AI. Mình có thể bật/tắt thiết bị hoặc hẹn giờ tự động cho bạn — ví dụ: \"hãy tắt tất cả thiết bị phòng khách\" hoặc \"bật đèn lúc 6h tối\".'**
  String get assistantGreeting;

  /// No description provided for @assistantError.
  ///
  /// In vi, this message translates to:
  /// **'Xin lỗi, mình không kết nối được trợ lý AI. Kiểm tra mạng/backend rồi thử lại nhé.'**
  String get assistantError;

  /// No description provided for @assistantTyping.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get assistantTyping;

  /// No description provided for @notificationsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông báo'**
  String get notificationsLoadError;

  /// No description provided for @notifTagAutomation.
  ///
  /// In vi, this message translates to:
  /// **'Automation'**
  String get notifTagAutomation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
