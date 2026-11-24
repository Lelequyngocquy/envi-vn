import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:envivn/src/core/infrastructure/configs/env_config.dart';

void main() {
  group('Phase 5 Release Build Hardening Verification', () {
    test(
      'EnvConfig initializes cleanly via dart-define without asset bundle',
      () async {
        EnvConfig.reset();
        await EnvConfig.init();
        expect(EnvConfig.isInitialized, isTrue);
        expect(EnvConfig.appName, 'EnviVN');
        expect(EnvConfig.clientApiKey, isEmpty);
        expect(EnvConfig.osmTileUrl, startsWith('https://'));
        EnvConfig.loadFromString(
          'APP_ENV=staging\nBACKEND_BASE_URL=https://api.envivn.vn\nCLIENT_API_KEY=key-123',
        );
        expect(EnvConfig.appEnv, 'staging');
        expect(EnvConfig.backendBaseUrl, 'https://api.envivn.vn');
        expect(EnvConfig.clientApiKey, 'key-123');
        EnvConfig.reset();
      },
    );

    test(
      'pubspec.yaml does not bundle .env or .env_example as Flutter assets',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        expect(pubspec, isNot(contains('.env_example')));
        expect(
          RegExp(r'^\s*-\s*\.env\b', multiLine: true).hasMatch(pubspec),
          isFalse,
        );
      },
    );

    test(
      'AndroidManifest and network_security_config block cleartext in release and scope it to debug',
      () {
        final manifest = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
        expect(
          manifest,
          contains(
            'android:networkSecurityConfig="@xml/network_security_config"',
          ),
        );
        final releaseNetCfg = File(
          'android/app/src/main/res/xml/network_security_config.xml',
        ).readAsStringSync();
        expect(releaseNetCfg, contains('cleartextTrafficPermitted="false"'));
        final debugNetCfg = File(
          'android/app/src/debug/res/xml/network_security_config.xml',
        ).readAsStringSync();
        expect(debugNetCfg, contains('10.0.2.2'));
        expect(debugNetCfg, contains('localhost'));
      },
    );

    test(
      'build.gradle.kts enables R8 minification, resource shrinking, and external release signing',
      () {
        final gradle = File('android/app/build.gradle.kts').readAsStringSync();
        expect(gradle, contains('isMinifyEnabled = true'));
        expect(gradle, contains('isShrinkResources = true'));
        expect(gradle, contains('proguard-rules.pro'));
        expect(gradle, contains('key.properties'));
        expect(gradle, contains('ENVIVN_KEYSTORE_PATH'));
        expect(File('android/app/proguard-rules.pro').existsSync(), isTrue);
      },
    );

    test('analysis_options.yaml does not suppress deprecated_member_use', () {
      final options = File('analysis_options.yaml').readAsStringSync();
      expect(options, isNot(contains('deprecated_member_use')));
    });
  });
}
