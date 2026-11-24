import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:envivn/src/core/infrastructure/configs/env_config.dart';
import 'package:envivn/src/core/infrastructure/datasources/local/local_storage.dart';
import 'package:envivn/src/features/map/infrastructure/repositories/nasa_firms_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late SharedPreferences prefs;

  final sampleBackendResponse = jsonEncode({
    'total': 2,
    'source': 'NASA FIRMS VIIRS NOAA-20',
    'cached': false,
    'hotspots': [
      {
        'id': 'nasa_viirs_2026-10-19_629_14.0250_107.8200',
        'location_name': 'Khu vực Gia Lai',
        'province': 'Gia Lai',
        'latitude': 14.025,
        'longitude': 107.82,
        'brightness_kelvin': 345.5,
        'frp': 24.5,
        'confidence': 95.0,
        'fire_type': 'Điểm phát xạ nhiệt ở vùng cao (công suất cao)',
        'is_active_fire': true,
        'prone_season': 'Dữ liệu vệ tinh thời gian thực (NOAA-20 VIIRS)',
        'detected_time': '19/10 lúc 13:29 (Vệ tinh NOAA-20 quét)',
        'description': 'Tín hiệu phát xạ nhiệt tăng cao (24.5 MW)',
      },
      {
        'id': 'nasa_viirs_2026-10-19_629_10.2614_104.7028',
        'location_name': 'Khu vực Kiên Giang',
        'province': 'Kiên Giang',
        'latitude': 10.2614,
        'longitude': 104.7028,
        'brightness_kelvin': 330.83,
        'frp': 2.91,
        'confidence': 80.0,
        'fire_type': 'Điểm nhiệt bề mặt ở vùng đồng bằng',
        'is_active_fire': true,
        'prone_season': 'Dữ liệu vệ tinh thời gian thực (NOAA-20 VIIRS)',
        'detected_time': '19/10 lúc 13:29 (Vệ tinh NOAA-20 quét)',
        'description': 'Ghi nhận tín hiệu nhiệt bề mặt (2.9 MW)',
      },
    ],
  });

  setUp(() async {
    EnvConfig.reset();
    EnvConfig.loadFromString('BACKEND_BASE_URL=http://localhost:8080\nCLIENT_API_KEY=key-abc');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs: prefs);
  });

  group('NasaFirmsRepository Backend Thin Client Tests', () {
    test('fetches hotspots JSON from Backend /api/v1/hotspots and caches locally', () async {
      int requestCount = 0;
      Uri? capturedUri;
      String? capturedKey;
      final mockClient = MockClient((request) async {
        requestCount++;
        capturedUri = request.url;
        capturedKey = request.headers['x-api-key'];
        return http.Response(sampleBackendResponse, 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });
      final repository = NasaFirmsRepository(client: mockClient, storage: storage);
      final result = await repository.getVietnamActiveFires();
      expect(result.isSuccess, isTrue);
      expect(result.data?.length, 2);
      expect(requestCount, 1);
      expect(capturedUri.toString(), 'http://localhost:8080/api/v1/hotspots?force=false');
      expect(capturedKey, 'key-abc');
      final hotGiaLai = result.data!.firstWhere((s) => s.province == 'Gia Lai');
      expect(hotGiaLai.confidence, 95.0);
      expect(hotGiaLai.latitude, 14.025);
      expect(hotGiaLai.isActiveFire, isTrue);
      expect(hotGiaLai.detectedTime, contains('13:29'));
      expect(storage.getCachedThermalHotspots()?.length, 2);
    });

    test('serves from 15-minute TTL cache without sending HTTP request until forceRefresh', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(sampleBackendResponse, 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });
      final repository = NasaFirmsRepository(client: mockClient, storage: storage);
      await repository.getVietnamActiveFires();
      expect(requestCount, 1);
      final cachedResult = await repository.getVietnamActiveFires();
      expect(cachedResult.isSuccess, isTrue);
      expect(cachedResult.data!.length, 2);
      expect(requestCount, 1);
      final forcedResult = await repository.getVietnamActiveFires(forceRefresh: true);
      expect(forcedResult.isSuccess, isTrue);
      expect(requestCount, 2);
    });

    test('falls back to stale real cache on HTTP 429 rate limit', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(sampleBackendResponse, 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('Rate limit exceeded', 429);
      });
      final repository = NasaFirmsRepository(client: mockClient, storage: storage);
      await repository.getVietnamActiveFires();
      expect(repository.isServingCachedData, isFalse);
      final result429 = await repository.getVietnamActiveFires(forceRefresh: true);
      expect(result429.isSuccess, isTrue);
      expect(result429.data!.length, 2);
      expect(repository.isServingCachedData, isTrue);
      expect(result429.message, contains('giới hạn tần suất'));
    });

    test('returns failure with empty list when storage is empty and network fails', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused', request.url);
      });
      final repository = NasaFirmsRepository(client: mockClient, storage: storage);
      final result = await repository.getVietnamActiveFires();
      expect(result.isSuccess, isFalse);
      expect(result.data, isEmpty);
    });
  });
}
