import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/entities/base.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/domain/entities/location_result.dart';
import 'package:envivn/src/core/domain/entities/thermal_hotspot_entity.dart';
import 'package:envivn/src/core/domain/interfaces/i_air_quality_repository.dart';
import 'package:envivn/src/core/domain/interfaces/i_details_repository.dart';
import 'package:envivn/src/core/domain/interfaces/i_location_service.dart';
import 'package:envivn/src/core/infrastructure/datasources/local/local_storage.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_cubit.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_cubit.dart';
import 'package:envivn/src/features/details/presentation/cubits/details_cubit.dart';
import 'package:envivn/src/features/home/presentation/cubits/home_dashboard_cubit.dart';
import 'package:envivn/src/features/map/domain/entities/station_entity.dart';

class _StubLocationService implements ILocationService {
  bool granted = true;

  @override
  Future<bool> checkPermissionGranted() async => granted;

  @override
  Future<LocationResult> getCurrentLocation() async => const LocationResult(
    latitude: 16.0544,
    longitude: 108.2022,
    cityName: 'Đà Nẵng',
  );
}

class _CountingDetailsRepo implements IDetailsRepository {
  int fetchCount = 0;

  @override
  DetailsEntity? getCachedDetails({double? latitude, double? longitude}) =>
      null;

  @override
  Future<BaseResult<DetailsEntity>> getDetailsForecast({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    fetchCount++;
    return const BaseResult(
      success: true,
      data: DetailsEntity(currentTemp: 28.0),
    );
  }
}

class _CountingAqiRepo implements IAirQualityRepository {
  int fetchCount = 0;

  @override
  AirQualityEntity? getCachedAirQuality({
    double? latitude,
    double? longitude,
  }) => null;

  @override
  Future<BaseResult<AirQualityEntity>> getAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    fetchCount++;
    return const BaseResult(success: true, data: AirQualityEntity(usAqi: 44));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Clean Architecture & AppLocationCubit Tests', () {
    test('Core domain entities implement Equatable value equality', () {
      const aqi1 = AirQualityEntity(usAqi: 65, pm25: 19.5);
      const aqi2 = AirQualityEntity(usAqi: 65, pm25: 19.5);
      expect(aqi1, equals(aqi2));
      const det1 = DetailsEntity(currentTemp: 30.0, surfacePressure: 1011.0);
      const det2 = DetailsEntity(currentTemp: 30.0, surfacePressure: 1011.0);
      expect(det1, equals(det2));
      final ts = DateTime.utc(2026, 11, 24);
      final st1 = StationEntity(
        id: 's1',
        name: 'A',
        province: 'Hà Nội',
        latitude: 21.0,
        longitude: 105.8,
        aqi: 50,
        pm25: 12.0,
        pm10: 20.0,
        updatedAt: ts,
      );
      final st2 = StationEntity(
        id: 's1',
        name: 'A',
        province: 'Hà Nội',
        latitude: 21.0,
        longitude: 105.8,
        aqi: 50,
        pm25: 12.0,
        pm10: 20.0,
        updatedAt: ts,
      );
      expect(st1, equals(st2));
      const h1 = ThermalHotspotEntity(
        id: 'h1',
        locationName: 'Gia Lai',
        province: 'Gia Lai',
        latitude: 14.0,
        longitude: 108.0,
        brightnessKelvin: 330.0,
        fireType: 'Active',
        confidence: 90.0,
        isActiveFire: true,
        proneSeason: 'Dry',
        description: 'Test',
      );
      const h2 = ThermalHotspotEntity(
        id: 'h1',
        locationName: 'Gia Lai',
        province: 'Gia Lai',
        latitude: 14.0,
        longitude: 108.0,
        brightnessKelvin: 330.0,
        fireType: 'Active',
        confidence: 90.0,
        isActiveFire: true,
        proneSeason: 'Dry',
        description: 'Test',
      );
      expect(h1, equals(h2));
    });

    test(
      'AppLocationCubit persists full location metadata without losing id, province, or originType',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = LocalStorage(prefs: prefs);
        final locCubit = AppLocationCubit(
          cacheStore: storage,
          locationService: _StubLocationService(),
        );
        final customPin = AppLocationEntity.customPin(
          latitude: 14.025,
          longitude: 107.82,
          referenceProvince: 'Gia Lai',
          distanceKm: 4.2,
        );
        await locCubit.selectLocation(customPin);
        final restored = storage.getSelectedLocation();
        expect(restored, equals(customPin));
        expect(restored?.originType, LocationOriginType.customMapPin);
        expect(restored?.referenceProvinceName, 'Gia Lai');
        expect(restored?.distanceToNearestProvinceKm, 4.2);
        await locCubit.close();
      },
    );

    test(
      'HomeDashboardCubit reacts automatically to external AppLocationCubit updates from Map or Details',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = LocalStorage(prefs: prefs);
        final detailsRepo = _CountingDetailsRepo();
        final aqiRepo = _CountingAqiRepo();
        final locCubit = AppLocationCubit(
          cacheStore: storage,
          locationService: _StubLocationService(),
        );
        final detailsCubit = DetailsCubit(repository: detailsRepo);
        final aqiCubit = AirQualityCubit(repository: aqiRepo);
        final homeCubit = HomeDashboardCubit(
          appLocationCubit: locCubit,
          detailsCubit: detailsCubit,
          airQualityCubit: aqiCubit,
        );
        final hue = AppLocationEntity.city(
          name: 'Huế',
          province: 'Thừa Thiên Huế',
          latitude: 16.4637,
          longitude: 107.5909,
        );
        await locCubit.syncLocationFromMap(hue);
        await pumpEventQueue();
        expect(homeCubit.state.currentCity, equals(hue));
        expect(detailsRepo.fetchCount, 1);
        expect(aqiRepo.fetchCount, 1);
        await homeCubit.close();
        await locCubit.close();
        await detailsCubit.close();
        await aqiCubit.close();
      },
    );
  });
}
