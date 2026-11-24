import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/infrastructure/configs/env_config.dart';
import 'package:envivn/src/core/infrastructure/datasources/local/local_storage.dart';
import 'package:envivn/src/core/infrastructure/datasources/network/api/restful_request.dart';
import 'package:envivn/src/features/air_quality/infrastructure/repositories/air_quality_repository.dart';
import 'package:envivn/src/features/details/infrastructure/repositories/details_repository.dart';
import 'package:envivn/src/features/map/domain/entities/vietnam_province.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    EnvConfig.reset();
    EnvConfig.loadFromString('BACKEND_BASE_URL=http://localhost:8080\nCLIENT_API_KEY=thin-client-key');
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs: prefs);
  });

  group('Phase 2 Strict Thin Client Repository Tests', () {
    test('DetailsRepository calls Backend /api/v1/weather and parses hourly/daily JSON safely', () async {
      Uri? capturedUri;
      String? capturedKey;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedKey = request.headers['x-api-key'];
        return http.Response(
          jsonEncode({
            'temperature': 30.2,
            'apparent_temperature': 33.1,
            'relative_humidity': 76.4,
            'precipitation': 1.5,
            'weather_code': 61.0,
            'wind_speed': 11.2,
            'uv_index': 7.5,
            'surface_pressure': 1009.5,
            'hourly': [
              {
                'time': '2026-11-24T11:00',
                'temperature': 30.5,
                'relative_humidity': 75,
                'precipitation_probability': 40,
                'weather_code': 61,
              },
              {
                'time': 'invalid-date',
                'temperature': 99.0,
                'relative_humidity': 50,
                'precipitation_probability': 10,
                'weather_code': 0,
              },
            ],
            'daily': [
              {
                'date': '2026-11-24',
                'weather_code': 61,
                'max_temp': 32.0,
                'min_temp': 24.5,
                'precipitation_sum': 8.2,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = DetailsRepository(network: RestfulRequest(client: mockClient), storage: storage);
      final res = await repo.getDetailsForecast(latitude: 21.0285, longitude: 105.8542);
      expect(capturedUri?.host, 'localhost');
      expect(capturedUri?.path, '/api/v1/weather');
      expect(capturedUri?.queryParameters['lat'], '21.0285');
      expect(capturedUri?.queryParameters['lon'], '105.8542');
      expect(capturedKey, 'thin-client-key');
      expect(res.isSuccess, isTrue);
      expect(res.data?.currentTemp, 30.2);
      expect(res.data?.relativeHumidity, 76);
      expect(res.data?.weatherCode, 61);
      expect(res.data?.surfacePressure, 1009.5);
      expect(res.data?.hourlyForecast.length, 1);
      expect(res.data?.dailyForecast.length, 1);
    });

    test('AirQualityRepository calls Backend /api/v1/air-quality and parses pollutants + hourly AQI', () async {
      Uri? capturedUri;
      String? capturedKey;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedKey = request.headers['x-api-key'];
        return http.Response(
          jsonEncode({
            'us_aqi': 88.2,
            'european_aqi': 54,
            'pm25': 29.4,
            'pm10': 51.0,
            'co': 420.0,
            'no2': 19.2,
            'so2': 8.5,
            'o3': 62.0,
            'hourly': [
              {'time': '2026-11-24T11:00', 'us_aqi': 88, 'pm25': 29.4, 'pm10': 51.0},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = AirQualityRepository(network: RestfulRequest(client: mockClient), storage: storage);
      final res = await repo.getAirQuality(latitude: 10.7769, longitude: 106.7009);
      expect(capturedUri?.host, 'localhost');
      expect(capturedUri?.path, '/api/v1/air-quality');
      expect(capturedUri?.queryParameters['lat'], '10.7769');
      expect(capturedUri?.queryParameters['lon'], '106.7009');
      expect(capturedKey, 'thin-client-key');
      expect(res.isSuccess, isTrue);
      expect(res.data?.usAqi, 88);
      expect(res.data?.pm25, 29.4);
      expect(res.data?.carbonMonoxide, 420.0);
      expect(res.data?.hourlyAqi.length, 1);
    });

    test('VietnamProvince covers all 63 provinces plus Hoang Sa & Truong Sa and WeatherCodeHelper aligns WMO freezing rain', () {
      expect(VietnamProvince.values.length, 65);
      expect(VietnamProvince.findClosest(20.65, 106.05).province, VietnamProvince.hungYen);
      expect(VietnamProvince.findClosest(16.53, 112.03).province, VietnamProvince.hoangSa);
      expect(VietnamProvince.findClosest(9.88, 114.25).province, VietnamProvince.truongSa);
      expect(WeatherCodeHelper.getInfo(56).isRain, isTrue);
      expect(WeatherCodeHelper.getInfo(66).isRain, isTrue);
      expect(WeatherCodeHelper.getInfo(67).isRain, isTrue);
    });
  });
}
