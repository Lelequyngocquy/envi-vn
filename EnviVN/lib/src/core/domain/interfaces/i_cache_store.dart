import '../entities/app_location_entity.dart';

/// Pure domain contract for local cache and selected-location persistence.
abstract class ICacheStore {
  Future<void> saveCachedWeather(
    Map<String, dynamic> data, {
    double? lat,
    double? lon,
    Duration ttl = const Duration(minutes: 30),
  });

  Map<String, dynamic>? getCachedWeather({double? lat, double? lon, bool checkTtl = false});

  bool isWeatherCacheValid({required double lat, required double lon});

  Future<void> saveCachedAirQuality(
    Map<String, dynamic> data, {
    double? lat,
    double? lon,
    Duration ttl = const Duration(minutes: 30),
  });

  Map<String, dynamic>? getCachedAirQuality({double? lat, double? lon, bool checkTtl = false});

  bool isAirQualityCacheValid({required double lat, required double lon});

  Future<void> saveSelectedLocation(AppLocationEntity location);

  AppLocationEntity? getSelectedLocation();

  Future<void> saveSelectedCity(String cityName, double lat, double lon);

  Map<String, dynamic>? getSelectedCity();

  Future<void> saveLastUpdateTime();

  DateTime? getLastUpdateTime();

  Future<void> saveLocationPermission(bool isGranted);

  bool isLocationPermissionGranted();

  Future<void> saveCachedThermalHotspots(List<Map<String, dynamic>> spots);

  List<Map<String, dynamic>>? getCachedThermalHotspots();

  DateTime? getThermalLastUpdateTime();

  Future<void> clearAll();
}
