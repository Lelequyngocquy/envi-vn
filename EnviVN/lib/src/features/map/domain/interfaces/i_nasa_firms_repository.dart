import '../../../../core/domain/entities/base.dart';
import '../../../../core/domain/entities/thermal_hotspot_entity.dart';

abstract class INasaFirmsRepository {
  Future<BaseResult<List<ThermalHotspotEntity>>> getVietnamActiveFires({
    bool forceRefresh = false,
  });

  DateTime? getLastUpdateTime();

  bool get isServingCachedData;
}
