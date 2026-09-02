import 'package:shared_preferences/shared_preferences.dart';

const String kAppLockEnabledKey = 'asset_os_app_lock_enabled';
const String kAppLockPinKey = 'asset_os_app_lock_pin';
const String kAppLockBiometricKey = 'asset_os_app_lock_biometric';
const String kHidePricesKey = 'asset_os_hide_prices';
const String kHidePhoneNumbersKey = 'asset_os_hide_phone_numbers';
const String kMediaRetentionDaysKey = 'asset_os_media_retention_days';
const String kAnalyticsDisabledKey = 'asset_os_analytics_disabled';

/// Offline privacy prefs (distinct from handover verification PIN).
class PrivacySettings {
  const PrivacySettings({
    required this.appLockEnabled,
    required this.appLockPin,
    required this.biometricEnabled,
    required this.hidePrices,
    required this.hidePhoneNumbers,
    required this.mediaRetentionDays,
    required this.analyticsDisabled,
  });

  final bool appLockEnabled;
  final String? appLockPin;
  final bool biometricEnabled;
  final bool hidePrices;
  final bool hidePhoneNumbers;
  final int mediaRetentionDays;
  final bool analyticsDisabled;

  bool get hasValidAppLockPin {
    final String? pin = appLockPin;
    return pin != null && pin.length >= 4 && pin.length <= 6;
  }

  PrivacySettings copyWith({
    bool? appLockEnabled,
    String? appLockPin,
    bool clearAppLockPin = false,
    bool? biometricEnabled,
    bool? hidePrices,
    bool? hidePhoneNumbers,
    int? mediaRetentionDays,
    bool? analyticsDisabled,
  }) {
    return PrivacySettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPin: clearAppLockPin ? null : (appLockPin ?? this.appLockPin),
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      hidePrices: hidePrices ?? this.hidePrices,
      hidePhoneNumbers: hidePhoneNumbers ?? this.hidePhoneNumbers,
      mediaRetentionDays: mediaRetentionDays ?? this.mediaRetentionDays,
      analyticsDisabled: analyticsDisabled ?? this.analyticsDisabled,
    );
  }

  static PrivacySettings fromPreferences(SharedPreferences preferences) {
    return PrivacySettings(
      appLockEnabled: preferences.getBool(kAppLockEnabledKey) ?? false,
      appLockPin: preferences.getString(kAppLockPinKey),
      biometricEnabled: preferences.getBool(kAppLockBiometricKey) ?? false,
      hidePrices: preferences.getBool(kHidePricesKey) ?? false,
      hidePhoneNumbers: preferences.getBool(kHidePhoneNumbersKey) ?? false,
      mediaRetentionDays: preferences.getInt(kMediaRetentionDaysKey) ?? 30,
      analyticsDisabled: preferences.getBool(kAnalyticsDisabledKey) ?? true,
    );
  }

  Future<void> persist(SharedPreferences preferences) async {
    await preferences.setBool(kAppLockEnabledKey, appLockEnabled);
    if (appLockPin == null || appLockPin!.isEmpty) {
      await preferences.remove(kAppLockPinKey);
    } else {
      await preferences.setString(kAppLockPinKey, appLockPin!);
    }
    await preferences.setBool(kAppLockBiometricKey, biometricEnabled);
    await preferences.setBool(kHidePricesKey, hidePrices);
    await preferences.setBool(kHidePhoneNumbersKey, hidePhoneNumbers);
    await preferences.setInt(kMediaRetentionDaysKey, mediaRetentionDays);
    await preferences.setBool(kAnalyticsDisabledKey, analyticsDisabled);
  }
}
