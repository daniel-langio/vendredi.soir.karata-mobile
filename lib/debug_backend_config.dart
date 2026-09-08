import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class BackendOption {
  final String name;
  final String url;
  const BackendOption({required this.name, required this.url});
}

/// A debug-only way to switch which backend server the app talks to, entirely controlled by
/// assets/debug_backend_config.yml - flip "enabled" to false, or remove entries from the
/// "backends" list, to shrink or unplug this feature with no code changes.
///
/// Never active outside a debug build (kDebugMode is always false in profile/release builds,
/// including release APKs built by CI), regardless of what the config file says - so this can
/// never reach a real user even if the file is accidentally left enabled.
class DebugBackendConfig {
  DebugBackendConfig._();

  static const _assetPath = 'assets/debug_backend_config.yml';

  static Future<List<BackendOption>> load() async {
    if (!kDebugMode) return const [];
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final doc = loadYaml(raw) as YamlMap;
      if (doc['enabled'] != true) return const [];
      final list = doc['backends'] as YamlList? ?? YamlList.wrap(const []);
      return [
        for (final entry in list)
          BackendOption(
            name: (entry as YamlMap)['name'] as String,
            url: entry['url'] as String,
          ),
      ];
    } catch (_) {
      return const []; // Missing/malformed config file just turns this feature off, not a crash.
    }
  }
}
