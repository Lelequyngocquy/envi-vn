import '../entities/base.dart';
import '../entities/details_entity.dart';

abstract class IDetailsRepository {
  Future<BaseResult<DetailsEntity>> getDetailsForecast({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  });

  DetailsEntity? getCachedDetails({double? latitude, double? longitude});
}
