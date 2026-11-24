import '../../../../core/domain/entities/air_quality_entity.dart';

class AirQualityModel extends AirQualityEntity {
  const AirQualityModel({
    super.usAqi,
    super.europeanAqi,
    super.pm25,
    super.pm10,
    super.carbonMonoxide,
    super.nitrogenDioxide,
    super.sulphurDioxide,
    super.ozone,
    super.hourlyAqi,
    super.isOfflineCache,
  });

  static double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is num) return value.round();
    return double.tryParse(value?.toString() ?? '')?.round() ?? fallback;
  }

  /// Parses Backend /api/v1/air-quality JSON (and legacy cached Open-Meteo payloads).
  factory AirQualityModel.fromJson(
    Map<String, dynamic> json, {
    bool isOfflineCache = false,
  }) {
    if (json['current'] is Map) {
      return _fromLegacyOpenMeteoJson(json, isOfflineCache: isOfflineCache);
    }
    final hourlyList = <HourlyAqiPoint>[];
    if (json['hourly'] is List) {
      for (final item in (json['hourly'] as List)) {
        if (hourlyList.length >= 24) break;
        if (item is! Map) continue;
        final pointTime = DateTime.tryParse(item['time']?.toString() ?? '');
        if (pointTime == null) continue;
        hourlyList.add(
          HourlyAqiPoint(
            time: pointTime,
            aqi: _toInt(item['us_aqi']),
            pm25: _toDouble(item['pm25'] ?? item['pm2_5']),
            pm10: _toDouble(item['pm10']),
          ),
        );
      }
    }
    return AirQualityModel(
      usAqi: _toInt(json['us_aqi']),
      europeanAqi: _toInt(json['european_aqi']),
      pm25: _toDouble(json['pm25'] ?? json['pm2_5']),
      pm10: _toDouble(json['pm10']),
      carbonMonoxide: _toDouble(json['co'] ?? json['carbon_monoxide']),
      nitrogenDioxide: _toDouble(json['no2'] ?? json['nitrogen_dioxide']),
      sulphurDioxide: _toDouble(json['so2'] ?? json['sulphur_dioxide']),
      ozone: _toDouble(json['o3'] ?? json['ozone']),
      hourlyAqi: hourlyList,
      isOfflineCache: isOfflineCache,
    );
  }

  static AirQualityModel _fromLegacyOpenMeteoJson(
    Map<String, dynamic> json, {
    required bool isOfflineCache,
  }) {
    final current = Map<String, dynamic>.from(json['current'] as Map);
    final hourly = json['hourly'] is Map
        ? Map<String, dynamic>.from(json['hourly'] as Map)
        : <String, dynamic>{};
    final hourlyList = <HourlyAqiPoint>[];
    if (hourly['time'] is List) {
      final times = hourly['time'] as List;
      final aqis = hourly['us_aqi'] is List
          ? hourly['us_aqi'] as List
          : const [];
      final pm25s = hourly['pm2_5'] is List
          ? hourly['pm2_5'] as List
          : const [];
      final pm10s = hourly['pm10'] is List ? hourly['pm10'] as List : const [];
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      for (int i = 0; i < times.length && hourlyList.length < 24; i++) {
        final pointTime = DateTime.tryParse(times[i].toString());
        if (pointTime == null || !pointTime.isAfter(cutoff)) continue;
        hourlyList.add(
          HourlyAqiPoint(
            time: pointTime,
            aqi: i < aqis.length ? _toInt(aqis[i]) : 0,
            pm25: i < pm25s.length ? _toDouble(pm25s[i]) : 0.0,
            pm10: i < pm10s.length ? _toDouble(pm10s[i]) : 0.0,
          ),
        );
      }
    }
    return AirQualityModel(
      usAqi: _toInt(current['us_aqi']),
      europeanAqi: _toInt(current['european_aqi']),
      pm25: _toDouble(current['pm2_5']),
      pm10: _toDouble(current['pm10']),
      carbonMonoxide: _toDouble(current['carbon_monoxide']),
      nitrogenDioxide: _toDouble(current['nitrogen_dioxide']),
      sulphurDioxide: _toDouble(current['sulphur_dioxide']),
      ozone: _toDouble(current['ozone']),
      hourlyAqi: hourlyList,
      isOfflineCache: isOfflineCache,
    );
  }
}
