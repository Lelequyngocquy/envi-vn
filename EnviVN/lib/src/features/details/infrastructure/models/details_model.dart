import '../../domain/entities/details_entity.dart';

class DetailsModel extends DetailsEntity {
  const DetailsModel({
    super.currentTemp,
    super.apparentTemp,
    super.relativeHumidity,
    super.precipitation,
    super.weatherCode,
    super.windSpeed,
    super.uvIndex,
    super.surfacePressure,
    super.hourlyForecast,
    super.dailyForecast,
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

  /// Parses Backend /api/v1/weather JSON (and legacy cached Open-Meteo payloads).
  factory DetailsModel.fromJson(
    Map<String, dynamic> json, {
    bool isOfflineCache = false,
  }) {
    if (json['current'] is Map) {
      return _fromLegacyOpenMeteoJson(json, isOfflineCache: isOfflineCache);
    }
    final hourlyList = <HourlyDetailsPoint>[];
    if (json['hourly'] is List) {
      for (final item in (json['hourly'] as List)) {
        if (hourlyList.length >= 24) break;
        if (item is! Map) continue;
        final pointTime = DateTime.tryParse(item['time']?.toString() ?? '');
        if (pointTime == null) continue;
        hourlyList.add(
          HourlyDetailsPoint(
            time: pointTime,
            temperature: _toDouble(item['temperature']),
            humidity: _toInt(item['relative_humidity']),
            precipitationProbability: _toInt(item['precipitation_probability']),
            weatherCode: _toInt(item['weather_code']),
          ),
        );
      }
    }
    final dailyList = <DailyDetailsPoint>[];
    if (json['daily'] is List) {
      for (final item in (json['daily'] as List)) {
        if (dailyList.length >= 7) break;
        if (item is! Map) continue;
        final date = DateTime.tryParse(item['date']?.toString() ?? '');
        if (date == null) continue;
        dailyList.add(
          DailyDetailsPoint(
            date: date,
            weatherCode: _toInt(item['weather_code']),
            maxTemp: _toDouble(item['max_temp']),
            minTemp: _toDouble(item['min_temp']),
            precipitationSum: _toDouble(item['precipitation_sum']),
          ),
        );
      }
    }
    return DetailsModel(
      currentTemp: _toDouble(json['temperature']),
      apparentTemp: _toDouble(json['apparent_temperature']),
      relativeHumidity: _toInt(json['relative_humidity']),
      precipitation: _toDouble(json['precipitation']),
      weatherCode: _toInt(json['weather_code']),
      windSpeed: _toDouble(json['wind_speed']),
      uvIndex: _toDouble(json['uv_index']),
      surfacePressure: _toDouble(json['surface_pressure'], 1013.0),
      hourlyForecast: hourlyList,
      dailyForecast: dailyList,
      isOfflineCache: isOfflineCache,
    );
  }

  static DetailsModel _fromLegacyOpenMeteoJson(
    Map<String, dynamic> json, {
    required bool isOfflineCache,
  }) {
    final current = Map<String, dynamic>.from(json['current'] as Map);
    final hourly = json['hourly'] is Map ? Map<String, dynamic>.from(json['hourly'] as Map) : <String, dynamic>{};
    final daily = json['daily'] is Map ? Map<String, dynamic>.from(json['daily'] as Map) : <String, dynamic>{};
    final hourlyList = <HourlyDetailsPoint>[];
    if (hourly['time'] is List) {
      final times = hourly['time'] as List;
      final temps = hourly['temperature_2m'] is List ? hourly['temperature_2m'] as List : const [];
      final humids = hourly['relative_humidity_2m'] is List ? hourly['relative_humidity_2m'] as List : const [];
      final rainProbs = hourly['precipitation_probability'] is List ? hourly['precipitation_probability'] as List : const [];
      final codes = hourly['weather_code'] is List ? hourly['weather_code'] as List : const [];
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      for (int i = 0; i < times.length && hourlyList.length < 24; i++) {
        final pointTime = DateTime.tryParse(times[i].toString());
        if (pointTime == null || !pointTime.isAfter(cutoff)) continue;
        hourlyList.add(
          HourlyDetailsPoint(
            time: pointTime,
            temperature: i < temps.length ? _toDouble(temps[i]) : 0.0,
            humidity: i < humids.length ? _toInt(humids[i]) : 0,
            precipitationProbability: i < rainProbs.length ? _toInt(rainProbs[i]) : 0,
            weatherCode: i < codes.length ? _toInt(codes[i]) : 0,
          ),
        );
      }
    }
    final dailyList = <DailyDetailsPoint>[];
    if (daily['time'] is List) {
      final dates = daily['time'] as List;
      final codes = daily['weather_code'] is List ? daily['weather_code'] as List : const [];
      final maxTemps = daily['temperature_2m_max'] is List ? daily['temperature_2m_max'] as List : const [];
      final minTemps = daily['temperature_2m_min'] is List ? daily['temperature_2m_min'] as List : const [];
      final rainSums = daily['precipitation_sum'] is List ? daily['precipitation_sum'] as List : const [];
      for (int i = 0; i < dates.length && dailyList.length < 7; i++) {
        final date = DateTime.tryParse(dates[i].toString());
        if (date == null) continue;
        dailyList.add(
          DailyDetailsPoint(
            date: date,
            weatherCode: i < codes.length ? _toInt(codes[i]) : 0,
            maxTemp: i < maxTemps.length ? _toDouble(maxTemps[i]) : 0.0,
            minTemp: i < minTemps.length ? _toDouble(minTemps[i]) : 0.0,
            precipitationSum: i < rainSums.length ? _toDouble(rainSums[i]) : 0.0,
          ),
        );
      }
    }
    return DetailsModel(
      currentTemp: _toDouble(current['temperature_2m']),
      apparentTemp: _toDouble(current['apparent_temperature']),
      relativeHumidity: _toInt(current['relative_humidity_2m']),
      precipitation: _toDouble(current['precipitation']),
      weatherCode: _toInt(current['weather_code']),
      windSpeed: _toDouble(current['wind_speed_10m']),
      uvIndex: _toDouble(current['uv_index']),
      surfacePressure: _toDouble(current['surface_pressure'], 1013.0),
      hourlyForecast: hourlyList,
      dailyForecast: dailyList,
      isOfflineCache: isOfflineCache,
    );
  }
}
