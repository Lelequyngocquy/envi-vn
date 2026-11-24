import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:envivn/src/core/infrastructure/configs/env_config.dart';
import 'package:envivn/src/core/infrastructure/datasources/network/api/restful_request.dart';
import 'package:envivn/src/features/map/infrastructure/repositories/map_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EnvConfig.reset();
    EnvConfig.loadFromString(
      'BACKEND_BASE_URL=http://localhost:8080\nCLIENT_API_KEY=test-client-key',
    );
  });

  group('MapRepository Backend Thin Client Tests', () {
    test(
      'getVietnamStations sends 1 request to Backend /api/v1/map/stations with x-api-key',
      () async {
        int requestCount = 0;
        Uri? capturedUri;
        Map<String, String>? capturedHeaders;
        final mockClient = MockClient((request) async {
          requestCount++;
          capturedUri = request.url;
          capturedHeaders = request.headers;
          final payload = {
            'total': 2,
            'cached': false,
            'stations': [
              {
                'id': 'st_hn_01',
                'name': 'Trạm Hoàn Kiếm',
                'province': 'Hà Nội',
                'latitude': 21.0285,
                'longitude': 105.8542,
                'aqi': 55,
                'pm25': 16.4,
                'pm10': 28.1,
                'temperature': 27.5,
                'apparent_temperature': 29.0,
                'weather_code': 2,
                'relative_humidity': 72,
                'wind_speed': 9.2,
                'precipitation': 0.0,
                'uv_index': 5.1,
                'updated_at': '2026-11-24T10:00:00+07:00',
              },
              {
                'id': 'st_hcm_01',
                'name': 'Trạm Quận 1',
                'province': 'TP. Hồ Chí Minh',
                'latitude': 10.7769,
                'longitude': 106.7009,
                'aqi': 78,
                'pm25': 24.0,
                'pm10': 42.0,
                'temperature': null,
                'updated_at': '2026-11-24T10:00:00+07:00',
              },
            ],
          };
          return http.Response(
            jsonEncode(payload),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final network = RestfulRequest(client: mockClient);
        final repository = MapRepository(network: network);
        final result = await repository.getVietnamStations();
        expect(requestCount, 1);
        expect(
          capturedUri.toString(),
          'http://localhost:8080/api/v1/map/stations',
        );
        expect(capturedHeaders?['x-api-key'], 'test-client-key');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
        expect(result.data?.first.aqi, 55);
        expect(result.data?.first.temperature, 27.5);
        expect(result.data?.last.temperature, isNull);
      },
    );

    test(
      'getVietnamStations returns empty failure instead of fabricated fallback stations on error',
      () async {
        final mockClient = MockClient(
          (request) async => http.Response('Internal Server Error', 500),
        );
        final network = RestfulRequest(client: mockClient);
        final repository = MapRepository(network: network);
        final result = await repository.getVietnamStations();
        expect(result.isSuccess, isFalse);
        expect(result.data, isEmpty);
      },
    );
  });
}
