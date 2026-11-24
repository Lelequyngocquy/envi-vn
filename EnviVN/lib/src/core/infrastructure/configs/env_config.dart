import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EnvConfig {
  EnvConfig._();

  static final Map<String, String> _envMap = {};
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Loads base config from .env_example and overrides from .env when available.
  static Future<void> init() async {
    try {
      final exampleContent = await rootBundle.loadString('.env_example');
      _parseAndMerge(exampleContent, isOverride: false);
      if (kDebugMode) {
        debugPrint('[EnvConfig] Loaded .env_example (${_envMap.length} vars)');
      }
    } catch (_) {}
    try {
      final envContent = await rootBundle.loadString('.env');
      final prevCount = _envMap.length;
      _parseAndMerge(envContent, isOverride: true);
      if (kDebugMode) {
        debugPrint('[EnvConfig] Loaded .env (+${_envMap.length - prevCount} vars)');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[EnvConfig] .env not bundled; using dart-define or defaults');
      }
    }
    _isInitialized = true;
  }

  /// Loads raw KEY=VALUE content directly for unit tests.
  static void loadFromString(String rawContent, {bool isOverride = true}) {
    _parseAndMerge(rawContent, isOverride: isOverride);
    _isInitialized = true;
  }

  /// Clears all loaded configuration for tests.
  static void reset() {
    _envMap.clear();
    _isInitialized = false;
  }

  static void _parseAndMerge(String content, {required bool isOverride}) {
    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final equalIndex = line.indexOf('=');
      if (equalIndex > 0) {
        final key = line.substring(0, equalIndex).trim();
        var value = line.substring(equalIndex + 1).trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
          if (value.length >= 2) {
            value = value.substring(1, value.length - 1);
          }
        }
        if (isOverride) {
          if (value.isNotEmpty || !_envMap.containsKey(key)) {
            _envMap[key] = value;
          }
        } else if (!_envMap.containsKey(key)) {
          _envMap[key] = value;
        }
      }
    }
  }

  static String get(String key, {String defaultValue = ''}) {
    final val = _envMap[key];
    if (val == null || val.isEmpty) return defaultValue;
    return val;
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    final val = _envMap[key]?.toLowerCase().trim();
    if (val == 'true' || val == '1' || val == 'yes') return true;
    if (val == 'false' || val == '0' || val == 'no') return false;
    return defaultValue;
  }

  static String get appName => get('APP_NAME', defaultValue: 'EnviVN');

  static String get appEnv => get('APP_ENV', defaultValue: 'development');

  static bool get isDebug => getBool('APP_DEBUG', defaultValue: kDebugMode);

  /// OpenStreetMap tile URL template for map rendering.
  static String get osmTileUrl => get('OSM_TILE_URL', defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

  /// User agent sent for map tiles.
  static String get mapUserAgent => get('MAP_USER_AGENT', defaultValue: 'com.envivn.envivn');

  /// Optional client API key sent via x-api-key header in staging/production.
  static String get clientApiKey {
    const defined = String.fromEnvironment('CLIENT_API_KEY');
    if (defined.isNotEmpty) return defined;
    return get('CLIENT_API_KEY', defaultValue: '');
  }

  /// Backend Service base URL (Strict Thin Client gateway).
  static String get backendBaseUrl {
    const defined = String.fromEnvironment('BACKEND_BASE_URL');
    if (defined.isNotEmpty) return defined;
    final configured = get('BACKEND_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }
}
