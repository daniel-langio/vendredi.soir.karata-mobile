import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether table sounds play at all. Lives outside GameSounds because that class is instantiated
/// per TableScreen, while the mute switch is one app-wide choice made in settings.
class SoundSettings extends ValueNotifier<bool> {
  SoundSettings._() : super(true);
  static final SoundSettings instance = SoundSettings._();

  static const _prefsKey = 'sound_enabled';

  /// Fire-and-forget from main(), the way LocaleController.load is.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
