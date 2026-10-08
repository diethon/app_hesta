// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Syna';

  @override
  String get welcomeBack => 'Chào mừng trở lại';

  @override
  String get loginSubtitle => 'Điều khiển ngôi nhà của bạn một cách dễ dàng';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get register => 'Đăng ký';

  @override
  String get needAssistance => 'Cần hỗ trợ?';

  @override
  String get home => 'Nhà';

  @override
  String get rooms => 'Phòng';

  @override
  String get automation => 'Tự động';

  @override
  String get assistant => 'Trợ lý';

  @override
  String get energy => 'Điện năng';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get settings => 'Cài đặt';

  @override
  String get notifications => 'Thông báo';

  @override
  String goodMorning(String name) {
    return 'Chào buổi sáng, $name';
  }

  @override
  String get everythingSecure => 'Mọi thứ an toàn';

  @override
  String activeDevices(int count) {
    return '$count thiết bị đang hoạt động';
  }

  @override
  String get quickScenes => 'Ngữ cảnh nhanh';

  @override
  String get favoriteDevices => 'Thiết bị yêu thích';

  @override
  String get recentActivity => 'Hoạt động gần đây';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get loading => 'Đang tải';

  @override
  String get emptyTitle => 'Chưa có dữ liệu';

  @override
  String get retry => 'Thử lại';

  @override
  String get offline => 'Đang ngoại tuyến, hiển thị dữ liệu cache';

  @override
  String get localMode => 'Kết nối Edge';

  @override
  String get cloudMode => 'Kết nối Cloud';

  @override
  String get deviceDetail => 'Chi tiết thiết bị';

  @override
  String get camera => 'Camera';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get onboardingTitle => 'Syna kết nối ngôi nhà thông minh Edge-first';

  @override
  String get onboardingSubtitle =>
      'Ưu tiên thiết bị nội bộ khi có Wi-Fi LAN và tự chuyển sang cloud khi cần.';

  @override
  String get continueAction => 'Tiếp tục';

  @override
  String get quickAccess => 'Truy cập nhanh';

  @override
  String get automations => 'Tự động hoá';

  @override
  String get automationsSubtitle => 'Kịch bản & quy tắc';

  @override
  String get cameraSubtitle => 'Xem trực tiếp';

  @override
  String get homeSecure => 'Nhà an toàn';

  @override
  String get homeSecureSubtitle => 'Mọi hệ thống hoạt động bình thường';

  @override
  String get homeAttention => 'Cần chú ý';

  @override
  String get homeAttentionSubtitle => 'Có cửa chưa khoá, hãy kiểm tra';

  @override
  String get doorsOpen => 'cửa mở';

  @override
  String get lightsOn => 'đèn bật';

  @override
  String get systemArmed => 'Hệ thống đã kích hoạt';

  @override
  String get systemDisarmed => 'Hệ thống chưa kích hoạt';

  @override
  String get sceneAllOff => 'Tắt hết';

  @override
  String get sceneArriveHome => 'Về nhà';

  @override
  String get sceneMovieNight => 'Xem phim';

  @override
  String get sceneGoodNight => 'Ngủ ngon';

  @override
  String get sceneAdd => 'Thêm ngữ cảnh';

  @override
  String get locked => 'Đã khoá';

  @override
  String get unlocked => 'Chưa khoá';

  @override
  String get secured => 'An toàn';

  @override
  String get deviceOn => 'Đang bật';

  @override
  String get deviceOff => 'Đang tắt';

  @override
  String get deviceOnline => 'Trực tuyến';

  @override
  String get deviceOffline => 'Ngoại tuyến';

  @override
  String get activityArrived => 'Alex đã về nhà';

  @override
  String get activityMorningRoutine => 'Kích hoạt kịch bản buổi sáng';

  @override
  String get activityPatioMotion => 'Phát hiện chuyển động ở sân';

  @override
  String get yourRooms => 'Phòng của bạn';

  @override
  String totalDevicesConnected(int count) {
    return '$count thiết bị đã kết nối';
  }

  @override
  String get securityCameras => 'Camera an ninh';

  @override
  String get camerasLive => 'Đang phát trực tiếp';

  @override
  String roomDevicesSummary(int count, int active) {
    return '$count thiết bị • $active đang bật';
  }

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterLighting => 'Chiếu sáng';

  @override
  String get filterElectric => 'Thiết bị điện';

  @override
  String get filterSensors => 'Cảm biến';

  @override
  String get filterOther => 'Khác';

  @override
  String get battery => 'Pin';

  @override
  String get colorTempWarm => 'Ấm';

  @override
  String get colorTempNeutral => 'Trung tính';

  @override
  String get colorTempCold => 'Lạnh';

  @override
  String get slideToUnlock => 'Kéo để mở khoá';

  @override
  String get slideToLock => 'Kéo để khoá';

  @override
  String get lockTempCode => 'Mã tạm thời';

  @override
  String get lockMembers => 'Thành viên';

  @override
  String get lockScenes => 'Ngữ cảnh';

  @override
  String get lockHistory => 'Lịch sử mở khoá';

  @override
  String get lockHistoryFingerprint => 'Mở bằng vân tay';

  @override
  String get lockHistoryKeypad => 'Mở bằng mã số';

  @override
  String get lockHistoryApp => 'Mở từ ứng dụng';

  @override
  String get schedule => 'Lịch trình';

  @override
  String get scheduleOnTime => 'Giờ bật';

  @override
  String get scheduleOffTime => 'Giờ tắt';

  @override
  String get usageHistory => 'Lịch sử sử dụng';

  @override
  String get fanAuto => 'Tự động';

  @override
  String get fanLow => 'Thấp';

  @override
  String get fanMedium => 'Vừa';

  @override
  String get fanHigh => 'Cao';

  @override
  String get volume => 'Âm lượng';

  @override
  String get management => 'Quản lý';

  @override
  String get createNew => 'Tạo mới';

  @override
  String get triggerOccurs => 'Khi điều kiện xảy ra';

  @override
  String get executeAction => 'Thực hiện hành động';

  @override
  String get triggerTime => 'Thời gian';

  @override
  String get triggerLocation => 'Vị trí';

  @override
  String get triggerDeviceState => 'Cảm biến';

  @override
  String get actionScenes => 'Ngữ cảnh';

  @override
  String get actionControlDevice => 'Điều khiển thiết bị';

  @override
  String get activeRules => 'Quy tắc đang chạy';

  @override
  String get noAutomationsYet =>
      'Chưa có quy tắc nào. Tạo quy tắc đầu tiên để ngôi nhà tự vận hành.';

  @override
  String get newScene => 'Ngữ cảnh mới';

  @override
  String devicesCount(int count) {
    return '$count thiết bị';
  }

  @override
  String get statusActive => 'Đang chạy';

  @override
  String get snapshot => 'Chụp';

  @override
  String get record => 'Ghi hình';

  @override
  String get talk => 'Đàm thoại';

  @override
  String get spotlight => 'Đèn';

  @override
  String get cameraEvents => 'Sự kiện';

  @override
  String get energyUsage => 'Điện năng tiêu thụ';

  @override
  String get energySubtitle => 'Giám sát tiêu thụ theo thời gian thực';

  @override
  String get periodDaily => 'Ngày';

  @override
  String get periodWeekly => 'Tuần';

  @override
  String get periodMonthly => 'Tháng';

  @override
  String get consumptionOverTime => 'Tiêu thụ theo thời gian';

  @override
  String get consumption => 'Tiêu thụ';

  @override
  String get deviceDistribution => 'Phân bổ theo thiết bị';

  @override
  String get categoryClimate => 'Điều hoà không khí';

  @override
  String get categoryRefrigeration => 'Tủ lạnh';

  @override
  String get categoryLighting => 'Chiếu sáng';

  @override
  String get categoryOthers => 'Khác';

  @override
  String get efficiencyTip => 'Mẹo tiết kiệm';

  @override
  String get efficiencyTipBody =>
      'Giảm điều hoà 2°C có thể tiết kiệm 12\$ trong tháng này.';

  @override
  String get totalUsage => 'Tổng tiêu thụ';

  @override
  String get estimatedCost => 'Chi phí ước tính';

  @override
  String get carbonFootprint => 'Dấu chân carbon';

  @override
  String get assistantTitle => 'Syna AI';

  @override
  String get assistantOnline => 'Trực tuyến • Sẵn sàng';

  @override
  String get askAnything => 'Hỏi Syna bất cứ điều gì...';

  @override
  String get suggestionEveningScene => 'Bật ngữ cảnh buổi tối';

  @override
  String get suggestionLowerAc => 'Giảm nhiệt độ điều hoà';

  @override
  String get suggestionLockDoor => 'Khoá cửa trước';

  @override
  String get suggestionEnergyReport => 'Xem báo cáo điện năng';

  @override
  String get groupAccount => 'Tài khoản';

  @override
  String get groupSecurity => 'Bảo mật';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageName => 'Tiếng Việt';

  @override
  String get privacy => 'Quyền riêng tư';

  @override
  String get securitySettings => 'Cài đặt bảo mật';

  @override
  String get homeMember => 'Thành viên nhà';

  @override
  String get markAllRead => 'Đọc tất cả';

  @override
  String get securityAlerts => 'Cảnh báo an ninh';

  @override
  String get deviceAlerts => 'Cảnh báo thiết bị';

  @override
  String get completedAutomations => 'Tự động hoá đã chạy';

  @override
  String get tagAlert => 'Cảnh báo';

  @override
  String get tagWarning => 'Chú ý';

  @override
  String get tagLowBattery => 'Pin yếu';

  @override
  String get tagOffline => 'Ngoại tuyến';

  @override
  String get tagAutomation => 'Tự động hoá';

  @override
  String get notifPatioMotion => 'Phát hiện chuyển động ở sân';

  @override
  String get notifDoorUnlocked => 'Cửa chưa được khoá';

  @override
  String get notifBatteryLow => 'Quạt văn phòng sắp hết pin';

  @override
  String get notifDeviceOffline => 'Quạt văn phòng mất kết nối';

  @override
  String get notifMorningRoutine => 'Đã kích hoạt kịch bản buổi sáng';

  @override
  String get notifArriveHome => 'Đã kích hoạt ngữ cảnh Về nhà';

  @override
  String get notifGoodNight => 'Đã hoàn tất ngữ cảnh Ngủ ngon';

  @override
  String get edgeFirstTitle => 'Ưu tiên backend Edge nội bộ';

  @override
  String get edgeFirstSubtitle =>
      'Dùng thiết bị Edge trong mạng LAN trước, cloud khi cần';

  @override
  String get privacyAndData => 'Quyền riêng tư và dữ liệu';

  @override
  String get privacyAndDataSubtitle =>
      'Hỗ trợ xoá tài khoản và xoá dữ liệu cục bộ';

  @override
  String get splashTagline => 'Atmospheric Intelligence';

  @override
  String get onboarding1Title => 'Điều khiển thế giới của bạn.';

  @override
  String get onboarding1Subtitle =>
      'Trải nghiệm cuộc sống tương lai với tự động hoá liền mạch và AI thấu hiểu.';

  @override
  String get onboarding2Title => 'Tự động hoá thông minh.';

  @override
  String get onboarding2Subtitle =>
      'Syna học thói quen của bạn để tự điều chỉnh ánh sáng, nhiệt độ và âm thanh.';

  @override
  String get onboarding3Title => 'An ninh toàn diện.';

  @override
  String get onboarding3Subtitle =>
      'An tâm với giám sát AI giữ ngôi nhà của bạn an toàn và riêng tư mọi lúc.';

  @override
  String get completeSetup => 'Hoàn tất thiết lập';

  @override
  String get getStarted => 'Bắt đầu';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get termsFooter =>
      'Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Quyền riêng tư của Syna.';

  @override
  String get orContinueWith => 'Hoặc tiếp tục với';

  @override
  String get signInWithFaceId => 'Đăng nhập bằng FaceID';

  @override
  String get newToApp => 'Lần đầu dùng Syna?';

  @override
  String get joinApp => 'Tham gia Syna';

  @override
  String get registerSubtitle =>
      'Tạo tài khoản để bắt đầu quản lý không gian thông minh của bạn.';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get agreeToTerms =>
      'Tôi đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư.';

  @override
  String get alreadyHaveAccountShort => 'Đã có tài khoản?';

  @override
  String get assistantGreeting =>
      'Xin chào! Mình là Syna AI. Mình có thể bật/tắt thiết bị hoặc hẹn giờ tự động cho bạn — ví dụ: \"hãy tắt tất cả thiết bị phòng khách\" hoặc \"bật đèn lúc 6h tối\".';

  @override
  String get assistantError =>
      'Xin lỗi, mình không kết nối được trợ lý AI. Kiểm tra mạng/backend rồi thử lại nhé.';

  @override
  String get assistantTyping => 'Đang xử lý...';

  @override
  String get notificationsEmpty => 'Chưa có thông báo nào';

  @override
  String get notificationsLoadError => 'Không tải được thông báo';

  @override
  String get notifTagAutomation => 'Automation';
}
