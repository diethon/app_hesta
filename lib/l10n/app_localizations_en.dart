// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Syna';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Control your environment with ease';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get createAccount => 'Create an account';

  @override
  String get register => 'Register';

  @override
  String get needAssistance => 'Need assistance?';

  @override
  String get home => 'Home';

  @override
  String get rooms => 'Rooms';

  @override
  String get automation => 'Automation';

  @override
  String get assistant => 'Assistant';

  @override
  String get energy => 'Energy';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String goodMorning(String name) {
    return 'Good Morning, $name';
  }

  @override
  String get everythingSecure => 'Everything is secure';

  @override
  String activeDevices(int count) {
    return '$count devices active';
  }

  @override
  String get quickScenes => 'Quick scenes';

  @override
  String get favoriteDevices => 'Favorite devices';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get viewAll => 'View all';

  @override
  String get loading => 'Loading';

  @override
  String get emptyTitle => 'No data yet';

  @override
  String get retry => 'Retry';

  @override
  String get offline => 'Offline, showing cached data';

  @override
  String get localMode => 'Edge connected';

  @override
  String get cloudMode => 'Cloud connected';

  @override
  String get deviceDetail => 'Device detail';

  @override
  String get camera => 'Camera';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get onboardingTitle => 'Syna connects your edge-first smart home';

  @override
  String get onboardingSubtitle =>
      'Prefer the local LAN edge backend and fall back to cloud when needed.';

  @override
  String get continueAction => 'Continue';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get automations => 'Automations';

  @override
  String get automationsSubtitle => 'Scenes & rules';

  @override
  String get cameraSubtitle => 'Watch live';

  @override
  String get homeSecure => 'Home Secure';

  @override
  String get homeSecureSubtitle => 'All systems are operating normally';

  @override
  String get homeAttention => 'Needs attention';

  @override
  String get homeAttentionSubtitle => 'A door is unlocked, please check';

  @override
  String get doorsOpen => 'doors open';

  @override
  String get lightsOn => 'lights on';

  @override
  String get systemArmed => 'System armed';

  @override
  String get systemDisarmed => 'System disarmed';

  @override
  String get sceneAllOff => 'All Off';

  @override
  String get sceneArriveHome => 'Arrive Home';

  @override
  String get sceneMovieNight => 'Movie Night';

  @override
  String get sceneGoodNight => 'Good Night';

  @override
  String get sceneAdd => 'Add Scene';

  @override
  String get locked => 'Locked';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get secured => 'Secured';

  @override
  String get deviceOn => 'On';

  @override
  String get deviceOff => 'Off';

  @override
  String get deviceOnline => 'Online';

  @override
  String get deviceOffline => 'Offline';

  @override
  String get activityArrived => 'Alex arrived home';

  @override
  String get activityMorningRoutine => 'Morning routine activated';

  @override
  String get activityPatioMotion => 'Patio motion detected';

  @override
  String get yourRooms => 'Your Rooms';

  @override
  String totalDevicesConnected(int count) {
    return '$count devices connected';
  }

  @override
  String get securityCameras => 'Security cameras';

  @override
  String get camerasLive => 'Streaming live';

  @override
  String roomDevicesSummary(int count, int active) {
    return '$count devices • $active on';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterLighting => 'Lighting';

  @override
  String get filterElectric => 'Appliances';

  @override
  String get filterSensors => 'Sensors';

  @override
  String get filterOther => 'Other';

  @override
  String get battery => 'Battery';

  @override
  String get colorTempWarm => 'Warm';

  @override
  String get colorTempNeutral => 'Neutral';

  @override
  String get colorTempCold => 'Cold';

  @override
  String get slideToUnlock => 'Slide to unlock';

  @override
  String get slideToLock => 'Slide to lock';

  @override
  String get lockTempCode => 'Temp code';

  @override
  String get lockMembers => 'Members';

  @override
  String get lockScenes => 'Scenes';

  @override
  String get lockHistory => 'Unlock history';

  @override
  String get lockHistoryFingerprint => 'Unlocked with fingerprint';

  @override
  String get lockHistoryKeypad => 'Unlocked with keypad';

  @override
  String get lockHistoryApp => 'Unlocked from app';

  @override
  String get schedule => 'Schedule';

  @override
  String get scheduleOnTime => 'On time';

  @override
  String get scheduleOffTime => 'Off time';

  @override
  String get usageHistory => 'Usage history';

  @override
  String get fanAuto => 'Auto';

  @override
  String get fanLow => 'Low';

  @override
  String get fanMedium => 'Med';

  @override
  String get fanHigh => 'High';

  @override
  String get volume => 'Volume';

  @override
  String get management => 'Management';

  @override
  String get createNew => 'Create New';

  @override
  String get triggerOccurs => 'Trigger occurs';

  @override
  String get executeAction => 'Execute action';

  @override
  String get triggerTime => 'Time';

  @override
  String get triggerLocation => 'Location';

  @override
  String get triggerDeviceState => 'Sensor';

  @override
  String get actionScenes => 'Scenes';

  @override
  String get actionControlDevice => 'Control Device';

  @override
  String get activeRules => 'Active Rules';

  @override
  String get noAutomationsYet =>
      'No rules yet. Create your first rule to let your home run itself.';

  @override
  String get newScene => 'New Scene';

  @override
  String devicesCount(int count) {
    return '$count devices';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get snapshot => 'Snapshot';

  @override
  String get record => 'Record';

  @override
  String get talk => 'Talk';

  @override
  String get spotlight => 'Light';

  @override
  String get cameraEvents => 'Events';

  @override
  String get energyUsage => 'Energy Usage';

  @override
  String get energySubtitle => 'Real-time consumption monitoring';

  @override
  String get periodDaily => 'Daily';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get consumptionOverTime => 'Consumption Over Time';

  @override
  String get consumption => 'Consumption';

  @override
  String get deviceDistribution => 'Device Distribution';

  @override
  String get categoryClimate => 'Climate Control';

  @override
  String get categoryRefrigeration => 'Refrigeration';

  @override
  String get categoryLighting => 'Smart Lighting';

  @override
  String get categoryOthers => 'Others';

  @override
  String get efficiencyTip => 'Efficiency Tip';

  @override
  String get efficiencyTipBody =>
      'Lowering AC by 2°C could save you \$12 this month.';

  @override
  String get totalUsage => 'Total Usage';

  @override
  String get estimatedCost => 'Est. Cost';

  @override
  String get carbonFootprint => 'Carbon Footprint';

  @override
  String get assistantTitle => 'Syna AI';

  @override
  String get assistantOnline => 'Online • Ready';

  @override
  String get askAnything => 'Ask Syna anything...';

  @override
  String get suggestionEveningScene => 'Set evening scene';

  @override
  String get suggestionLowerAc => 'Lower AC temp';

  @override
  String get suggestionLockDoor => 'Lock front door';

  @override
  String get suggestionEnergyReport => 'Show energy report';

  @override
  String get groupAccount => 'Account';

  @override
  String get groupSecurity => 'Security';

  @override
  String get language => 'Language';

  @override
  String get languageName => 'English';

  @override
  String get privacy => 'Privacy';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get homeMember => 'Home Member';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get securityAlerts => 'Security Alerts';

  @override
  String get deviceAlerts => 'Device Alerts';

  @override
  String get completedAutomations => 'Completed Automations';

  @override
  String get tagAlert => 'Alert';

  @override
  String get tagWarning => 'Warning';

  @override
  String get tagLowBattery => 'Low Battery';

  @override
  String get tagOffline => 'Offline';

  @override
  String get tagAutomation => 'Automation';

  @override
  String get notifPatioMotion => 'Patio motion detected';

  @override
  String get notifDoorUnlocked => 'Door left unlocked';

  @override
  String get notifBatteryLow => 'Office Fan battery low';

  @override
  String get notifDeviceOffline => 'Office Fan offline';

  @override
  String get notifMorningRoutine => 'Morning Routine activated';

  @override
  String get notifArriveHome => 'Arrive Home scene activated';

  @override
  String get notifGoodNight => 'Good Night scene completed';

  @override
  String get edgeFirstTitle => 'Use local Edge backend first';

  @override
  String get edgeFirstSubtitle =>
      'Prefer the LAN edge device, cloud when needed';

  @override
  String get privacyAndData => 'Privacy and data';

  @override
  String get privacyAndDataSubtitle =>
      'Delete account and clear local data supported';

  @override
  String get splashTagline => 'Atmospheric Intelligence';

  @override
  String get onboarding1Title => 'Control your world.';

  @override
  String get onboarding1Subtitle =>
      'Experience the future of living with seamless automation and AI-driven insights.';

  @override
  String get onboarding2Title => 'Intuitive Automation.';

  @override
  String get onboarding2Subtitle =>
      'Syna learns your routines to perfectly adjust lighting, climate, and sound automatically.';

  @override
  String get onboarding3Title => 'Total Security.';

  @override
  String get onboarding3Subtitle =>
      'Rest easy with AI-powered monitoring that keeps your sanctuary safe and private at all times.';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign In';

  @override
  String get termsFooter =>
      'By continuing, you agree to Syna\'s Terms & Privacy.';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get signInWithFaceId => 'Sign in with FaceID';

  @override
  String get newToApp => 'New to Syna?';

  @override
  String get joinApp => 'Join Syna';

  @override
  String get registerSubtitle =>
      'Create your account to start managing your smart space.';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get agreeToTerms =>
      'I agree to the Terms and Conditions and Privacy Policy.';

  @override
  String get alreadyHaveAccountShort => 'Already have an account?';

  @override
  String get assistantGreeting =>
      'Hello! I\'m Syna AI. I can control your devices or schedule automations — e.g. \"turn off all living room devices\" or \"turn on the lights at 6pm\".';

  @override
  String get assistantError =>
      'Sorry, I couldn\'t reach the AI assistant. Check your network/backend and try again.';

  @override
  String get assistantTyping => 'Thinking...';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsLoadError => 'Failed to load notifications';

  @override
  String get notifTagAutomation => 'Automation';
}
