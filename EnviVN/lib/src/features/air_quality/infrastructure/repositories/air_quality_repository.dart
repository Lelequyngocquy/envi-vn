import 'package:flutter/foundation.dart';

import '../../../../core/domain/entities/air_quality_entity.dart';
import '../../../../core/domain/entities/base.dart';
import '../../../../core/domain/interfaces/i_air_quality_repository.dart';
import '../../../../core/domain/interfaces/i_cache_store.dart';
import '../../../../core/infrastructure/datasources/network/api/configs/endpoint.dart';
import '../../../../core/infrastructure/datasources/network/api/restful_request.dart';
import '../models/air_quality_model.dart';
import '../paths/air_quality_paths.dart';

class AirQualityRepository implements IAirQualityRepository {
  final RestfulRequest network;
  final ICacheStore storage;

  AirQualityRepository({required this.network, required this.storage});

  @override
  Future<BaseResult<AirQualityEntity>> getAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final validCache = storage.getCachedAirQuality(lat: latitude, lon: longitude, checkTtl: true);
      if (validCache != null) {
        return BaseResult(success: true, data: AirQualityModel.fromJson(validCache));
      }
    }
    try {
      final endpoint = EndpointType(
        path: AirQualityPaths.airQuality,
        method: HttpMethod.get,
        params: {
          'lat': latitude,
          'lon': longitude,
          'force_refresh': forceRefresh,
        },
      );
      final response = await network.requestData(endpoint, showErrorToast: false);
      if (response.isSuccess && response.data is Map) {
        final dataMap = Map<String, dynamic>.from(response.data as Map);
        final airQuality = AirQualityModel.fromJson(dataMap);
        await storage.saveCachedAirQuality(dataMap, lat: latitude, lon: longitude);
        return BaseResult(success: true, data: airQuality);
      }
      final cached = getCachedAirQuality(latitude: latitude, longitude: longitude);
      if (cached != null) {
        return BaseResult(success: true, message: 'Đang hiển thị chỉ số không khí lưu ngoại tuyến', data: cached);
      }
      return BaseResult(success: false, message: response.message ?? 'Không thể tải chỉ số chất lượng không khí', data: const AirQualityEntity());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AirQualityRepository] Error: $e');
      }
      final cached = getCachedAirQuality(latitude: latitude, longitude: longitude);
      if (cached != null) {
        return BaseResult(success: true, message: 'Đang hiển thị chỉ số không khí từ bộ nhớ đệm', data: cached);
      }
      return BaseResult(success: false, message: 'Không thể tải chất lượng không khí lúc này. Vui lòng thử lại.', data: const AirQualityEntity());
    }
  }

  @override
  AirQualityEntity? getCachedAirQuality({double? latitude, double? longitude}) {
    final cachedJson = storage.getCachedAirQuality(lat: latitude, lon: longitude);
    if (cachedJson != null) {
      return AirQualityModel.fromJson(cachedJson, isOfflineCache: true);
    }
    return null;
  }
}
