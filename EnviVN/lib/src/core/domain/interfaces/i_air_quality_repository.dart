import '../entities/air_quality_entity.dart';
import '../entities/base.dart';

abstract class IAirQualityRepository {
  Future<BaseResult<AirQualityEntity>> getAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  });

  AirQualityEntity? getCachedAirQuality({double? latitude, double? longitude});
}
