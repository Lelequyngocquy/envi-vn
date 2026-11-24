import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_dialog.dart';
import 'package:envivn/src/features/details/presentation/widgets/aqi_24h_chart_card.dart';
import 'package:envivn/src/features/map/domain/entities/map_filter.dart';
import 'package:envivn/src/features/map/domain/entities/map_layer_type.dart';
import 'package:envivn/src/features/map/domain/entities/quick_city_target.dart';
import 'package:envivn/src/features/map/domain/entities/station_entity.dart';
import 'package:envivn/src/features/map/domain/utils/map_location_resolver.dart';
import 'package:envivn/src/features/map/presentation/cubits/map_state.dart';
import 'package:envivn/src/features/map/presentation/widgets/station_preview_card.dart';
import 'package:envivn/src/features/story_share/presentation/models/story_models.dart';
import 'package:envivn/src/features/story_share/presentation/widgets/story_mini_cards.dart';

void main() {
  final sampleStations = [
    StationEntity(
      id: 'st_good',
      name: 'Trạm Hoàn Kiếm',
      province: 'Hà Nội',
      latitude: 21.0285,
      longitude: 105.8542,
      aqi: 35,
      pm25: 10,
      pm10: 20,
      updatedAt: DateTime(2026),
      temperature: 28,
      apparentTemp: 30,
      humidity: 70,
      windSpeed: 10,
      uvIndex: 5,
      weatherCode: 1,
    ),
    StationEntity(
      id: 'st_mod',
      name: 'Trạm Hải Châu',
      province: 'Đà Nẵng',
      latitude: 16.0544,
      longitude: 108.2022,
      aqi: 78,
      pm25: 25,
      pm10: 40,
      updatedAt: DateTime(2026),
    ),
    StationEntity(
      id: 'st_bad',
      name: 'Trạm Quận 1',
      province: 'TP.HCM',
      latitude: 10.8231,
      longitude: 106.6297,
      aqi: 155,
      pm25: 62,
      pm10: 95,
      updatedAt: DateTime(2026),
    ),
  ];

  group('Phase 4 Refactor & Performance Verification', () {
    test('MapFilter enum filters MapState.filteredStations accurately', () {
      final base = MapState(stations: sampleStations);
      expect(base.filteredStations.length, 3);
      expect(
        base
            .copyWith(activeFilter: MapFilter.good)
            .filteredStations
            .map((s) => s.id),
        ['st_good'],
      );
      expect(
        base
            .copyWith(activeFilter: MapFilter.moderate)
            .filteredStations
            .map((s) => s.id),
        ['st_mod'],
      );
      expect(
        base
            .copyWith(activeFilter: MapFilter.unhealthy)
            .filteredStations
            .map((s) => s.id),
        ['st_bad'],
      );
    });

    test(
      'MapLocationResolver resolves closest station and dropped-pin metadata',
      () {
        final closest = MapLocationResolver.findClosestStation(
          sampleStations,
          21.03,
          105.85,
        );
        expect(closest.station?.id, 'st_good');
        expect(closest.distanceKm, lessThan(1.0));
        final byCity = MapLocationResolver.findStationByCityName(
          sampleStations,
          'Da Nang',
        );
        expect(byCity?.id, 'st_mod');
        final picked = MapLocationResolver.resolvePickedMeta(
          point: const LatLng(21.04, 105.86),
          stations: sampleStations,
          quickCities: QuickCityTarget.values,
        );
        expect(picked.province, 'Hà Nội');
        expect(picked.name, contains('Điểm ghim'));
      },
    );

    testWidgets(
      'StationPreviewCard strategy registry renders all MapLayerType variants',
      (tester) async {
        for (final layer in MapLayerType.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StationPreviewCard(
                  station: sampleStations.first,
                  activeLayer: layer,
                  onClose: () {},
                ),
              ),
            ),
          );
          expect(find.textContaining('Trạm Hoàn Kiếm'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'StoryModuleTile outdoorActivity reflects real ActivityAdviceHelper evaluation',
      (tester) async {
        const badAqi = AirQualityEntity(usAqi: 175, pm25: 90, pm10: 120);
        const rainyWeather = DetailsEntity(
          currentTemp: 27,
          apparentTemp: 29,
          weatherCode: 63,
          precipitation: 4.5,
          uvIndex: 2.0,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryModuleTile(
                type: StoryCardType.outdoorActivity,
                airQuality: badAqi,
                weather: rainyWeather,
                aqiInfo: AQIHelper.getAQIInfo(badAqi.usAqi),
                weatherInfo: WeatherCodeHelper.getInfo(
                  rainyWeather.weatherCode,
                ),
              ),
            ),
          ),
        );
        expect(find.text('Không nên'), findsOneWidget);
        expect(find.text('Nên tập luyện trong nhà'), findsOneWidget);
      },
    );

    testWidgets(
      'Aqi24hChartCard plots up to 24 hourly points with dynamic hour labels',
      (tester) async {
        final start = DateTime(2026, 6, 1, 3, 0);
        final points = List.generate(
          24,
          (i) => HourlyAqiPoint(
            time: start.add(Duration(hours: i)),
            aqi: 30 + i * 3,
            pm25: 10.0 + i,
            pm10: 20.0 + i,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Aqi24hChartCard(hourlyPoints: points),
              ),
            ),
          ),
        );
        final chart = tester.widget<LineChart>(find.byType(LineChart));
        expect(chart.data.lineBarsData.first.spots.length, 24);
        expect(find.text('03h'), findsOneWidget);
      },
    );

    testWidgets(
      'AppDialog avoids double BackdropFilter blur on inner glass card',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppDialog(title: 'Thông báo', content: 'Nội dung kiểm thử'),
            ),
          ),
        );
        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );
  });
}
