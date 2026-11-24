import '../../domain/entities/station_entity.dart';

class StationModel extends StationEntity {
  const StationModel({
    required super.id,
    required super.name,
    required super.province,
    required super.latitude,
    required super.longitude,
    required super.aqi,
    required super.pm25,
    required super.pm10,
    required super.updatedAt,
    super.temperature,
    super.apparentTemp,
    super.weatherCode,
    super.humidity,
    super.windSpeed,
    super.precipitation,
    super.uvIndex,
  });

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return double.tryParse(value.toString())?.round();
  }

  /// Parses Backend /api/v1/map/stations station item JSON.
  factory StationModel.fromBackendJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.tryParse(json['updated_at']?.toString() ?? '');
    return StationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      latitude: _toNullableDouble(json['latitude']) ?? 0.0,
      longitude: _toNullableDouble(json['longitude']) ?? 0.0,
      aqi: _toNullableInt(json['aqi']) ?? 0,
      pm25: _toNullableDouble(json['pm25']) ?? 0.0,
      pm10: _toNullableDouble(json['pm10']) ?? 0.0,
      temperature: _toNullableDouble(json['temperature']),
      apparentTemp: _toNullableDouble(json['apparent_temperature']),
      weatherCode: _toNullableInt(json['weather_code']),
      humidity: _toNullableInt(json['relative_humidity']),
      windSpeed: _toNullableDouble(json['wind_speed']),
      precipitation: _toNullableDouble(json['precipitation']),
      uvIndex: _toNullableDouble(json['uv_index']),
      updatedAt: parsedDate ?? DateTime.now(),
    );
  }
}
