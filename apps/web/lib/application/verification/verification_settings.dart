import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/verification/verification_models.dart';

const String kHandoverVerificationEnabledKey =
    'asset_os_handover_verification_enabled';
const String kHandoverVerificationMethodKey =
    'asset_os_handover_verification_method';
const String kHandoverPinKey = 'asset_os_handover_pin';
const String kConditionModeKey = 'asset_os_condition_mode';
const String kChecklistItemsKey = 'asset_os_checklist_items';

class VerificationSettingsStore {
  const VerificationSettingsStore(this._preferences);

  final SharedPreferences _preferences;

  VerificationSettings load() {
    final String? checklistRaw = _preferences.getString(kChecklistItemsKey);
    List<String> checklist = VerificationSettings.defaultChecklistItems;
    if (checklistRaw != null && checklistRaw.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(checklistRaw);
        if (decoded is List) {
          checklist = decoded.map((Object? e) => e.toString()).toList();
        }
      } on FormatException {
        checklist = VerificationSettings.defaultChecklistItems;
      }
    }
    return VerificationSettings(
      handoverEnabled:
          _preferences.getBool(kHandoverVerificationEnabledKey) ?? false,
      handoverMethod: VerificationMethod.parse(
        _preferences.getString(kHandoverVerificationMethodKey) ??
            VerificationMethod.manual.name,
      ),
      pin: _preferences.getString(kHandoverPinKey),
      conditionMode: ConditionMode.parse(
        _preferences.getString(kConditionModeKey) ??
            ConditionMode.basic.name,
      ),
      checklistItems: checklist,
    );
  }

  Future<void> persist(VerificationSettings settings) async {
    await _preferences.setBool(
      kHandoverVerificationEnabledKey,
      settings.handoverEnabled,
    );
    await _preferences.setString(
      kHandoverVerificationMethodKey,
      settings.handoverMethod.name,
    );
    if (settings.pin == null || settings.pin!.isEmpty) {
      await _preferences.remove(kHandoverPinKey);
    } else {
      await _preferences.setString(kHandoverPinKey, settings.pin!);
    }
    await _preferences.setString(
      kConditionModeKey,
      settings.conditionMode.name,
    );
    await _preferences.setString(
      kChecklistItemsKey,
      jsonEncode(settings.checklistItems),
    );
  }
}
