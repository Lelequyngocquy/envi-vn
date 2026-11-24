import 'package:flutter/foundation.dart';

import '../../../../core/domain/entities/base.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../../../core/domain/interfaces/i_cache_store.dart';
import '../../../../core/domain/interfaces/i_details_repository.dart';
import '../../../../core/infrastructure/datasources/network/api/configs/endpoint.dart';
import '../../../../core/infrastructure/datasources/network/api/restful_request.dart';
import '../models/details_model.dart';
import '../paths/details_paths.dart';

class DetailsRepository implements IDetailsRepository {
  final RestfulRequest network;
  final ICacheStore storage;

  DetailsRepository({required this.network, required this.storage});

  @override
  Future<BaseResult<DetailsEntity>> getDetailsForecast({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final validCache = storage.getCachedWeather(
        lat: latitude,
        lon: longitude,
        checkTtl: true,
      );
      if (validCache != null) {
        return BaseResult(
          success: true,
          data: DetailsModel.fromJson(validCache),
        );
      }
    }
    try {
      final endpoint = EndpointType(
        path: DetailsPaths.forecast,
        method: HttpMethod.get,
        params: {
          'lat': latitude,
          'lon': longitude,
          'force_refresh': forceRefresh,
        },
      );
      final response = await network.requestData(
        endpoint,
        showErrorToast: false,
      );
      if (response.isSuccess && response.data is Map) {
        final dataMap = Map<String, dynamic>.from(response.data as Map);
        final details = DetailsModel.fromJson(dataMap);
        await storage.saveCachedWeather(dataMap, lat: latitude, lon: longitude);
        return BaseResult(success: true, data: details);
      }
      final cached = getCachedDetails(latitude: latitude, longitude: longitude);
      if (cached != null) {
        return BaseResult(
          success: true,
          message: 'Đang hiển thị dữ liệu đã lưu ngoại tuyến',
          data: cached,
        );
      }
      return BaseResult(
        success: false,
        message: response.message ?? 'Không thể tải dự báo thời tiết chi tiết',
        data: const DetailsEntity(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DetailsRepository] Error: $e');
      }
      final cached = getCachedDetails(latitude: latitude, longitude: longitude);
      if (cached != null) {
        return BaseResult(
          success: true,
          message: 'Đang hiển thị dữ liệu lưu trong bộ nhớ máy',
          data: cached,
        );
      }
      return BaseResult(
        success: false,
        message: 'Không thể tải dự báo thời tiết lúc này. Vui lòng thử lại.',
        data: const DetailsEntity(),
      );
    }
  }

  @override
  DetailsEntity? getCachedDetails({double? latitude, double? longitude}) {
    final cachedJson = storage.getCachedWeather(lat: latitude, lon: longitude);
    if (cachedJson != null) {
      return DetailsModel.fromJson(cachedJson, isOfflineCache: true);
    }
    return null;
  }
}
