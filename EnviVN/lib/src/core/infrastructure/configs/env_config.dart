import 'package:flutter/foundation.dart';

/// Compile-time configuration reader backed by --dart-define / --dart-define-from-file.
class EnvConfig {
  EnvConfig._();

  static const String _defAppName = String.fromEnvironment('APP_NAME');
  static const String _defAppEnv = String.fromEnvironment('APP_ENV');
  static const String _defAppDebug = String.fromEnvironment('APP_DEBUG');
  static const String _defOsmTileUrl = String.fromEnvironment('OSM_TILE_URL');
  static const String _defMapUserAgent = String.fromEnvironment(
    'MAP_USER_AGENT',
  );
  static const String _defBackendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
  );
  static const String _defClientApiKey = String.fromEnvironment(
    'CLIENT_API_KEY',
  );
  static final Map<String, String> _testOverrides = {};
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Marks configuration ready without reading bundled .env asset files.
  static Future<void> init() async {
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint(
        '[EnvConfig] Initialized via dart-define (env=$appEnv, backend=$backendBaseUrl)',
      );
    }
  }

  /// Injects raw KEY=VALUE entries in unit tests without bundling .env files.
  @visibleForTesting
  static void loadFromString(String rawContent, {bool isOverride = true}) {
    final lines = rawContent.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final equalIndex = line.indexOf('=');
      if (equalIndex <= 0) continue;
      final key = line.substring(0, equalIndex).trim();
      var value = line.substring(equalIndex + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        if (value.length >= 2) {
          value = value.substring(1, value.length - 1);
        }
      }
      if (isOverride) {
        if (value.isNotEmpty || !_testOverrides.containsKey(key)) {
          _testOverrides[key] = value;
        }
      } else if (!_testOverrides.containsKey(key)) {
        _testOverrides[key] = value;
      }
    }
    _isInitialized = true;
  }

  /// Clears test overrides and resets initialization flag.
  @visibleForTesting
  static void reset() {
    _testOverrides.clear();
    _isInitialized = false;
  }

  static String _resolve(
    String key,
    String compileTimeValue, {
    String defaultValue = '',
  }) {
    final override = _testOverrides[key];
    if (override != null && override.isNotEmpty) return override;
    if (compileTimeValue.isNotEmpty) return compileTimeValue;
    return defaultValue;
  }

  static String get(String key, {String defaultValue = ''}) {
    final compileVal = switch (key) {
      'APP_NAME' => _defAppName,
      'APP_ENV' => _defAppEnv,
      'APP_DEBUG' => _defAppDebug,
      'OSM_TILE_URL' => _defOsmTileUrl,
      'MAP_USER_AGENT' => _defMapUserAgent,
      'BACKEND_BASE_URL' => _defBackendBaseUrl,
      'CLIENT_API_KEY' => _defClientApiKey,
      _ => '',
    };
    return _resolve(key, compileVal, defaultValue: defaultValue);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    final raw = get(key).toLowerCase().trim();
    if (raw == 'true' || raw == '1' || raw == 'yes') return true;
    if (raw == 'false' || raw == '0' || raw == 'no') return false;
    return defaultValue;
  }

  static String get appName =>
      _resolve('APP_NAME', _defAppName, defaultValue: 'EnviVN');

  static String get appEnv => _resolve(
    'APP_ENV',
    _defAppEnv,
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  static bool get isDebug => getBool('APP_DEBUG', defaultValue: kDebugMode);

  /// OpenStreetMap tile URL template for map rendering.
  static String get osmTileUrl => _resolve(
    'OSM_TILE_URL',
    _defOsmTileUrl,
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// User agent sent for map tiles.
  static String get mapUserAgent => _resolve(
    'MAP_USER_AGENT',
    _defMapUserAgent,
    defaultValue: 'com.envivn.envivn',
  );

  /// Optional client API key sent via x-api-key header in staging/production.
  static String get clientApiKey =>
      _resolve('CLIENT_API_KEY', _defClientApiKey);

  /// Backend Service base URL (Strict Thin Client gateway).
  static String get backendBaseUrl {
    final configured = _resolve('BACKEND_BASE_URL', _defBackendBaseUrl);
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
