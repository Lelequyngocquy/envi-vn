import 'package:flutter/foundation.dart';

import '../../../../core/domain/entities/base.dart';
import '../../../../core/infrastructure/datasources/network/api/configs/endpoint.dart';
import '../../../../core/infrastructure/datasources/network/api/restful_request.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/interfaces/i_map_repository.dart';
import '../models/station_model.dart';
import '../paths/map_paths.dart';

class MapRepository implements IMapRepository {
  final RestfulRequest network;

  MapRepository({required this.network});

  @override
  Future<BaseResult<List<StationEntity>>> getVietnamStations() async {
    try {
      final endpoint = EndpointType(path: MapPaths.stations, method: HttpMethod.get);
      final res = await network.requestData(endpoint, showErrorToast: false);
      if (res.isSuccess && res.data is Map) {
        final rawStations = (res.data as Map)['stations'];
        if (rawStations is List) {
          final stations = rawStations
              .whereType<Map>()
              .map((item) => StationModel.fromBackendJson(Map<String, dynamic>.from(item)))
              .where((s) => s.id.isNotEmpty)
              .toList();
          if (stations.isNotEmpty) {
            return BaseResult(success: true, data: stations);
          }
        }
      }
      return BaseResult(success: false, message: res.message ?? 'Không nhận được dữ liệu trạm quan trắc từ máy chủ.', data: const []);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MapRepository] Error: $e');
      }
      return BaseResult(success: false, message: 'Không thể tải danh sách trạm quan trắc lúc này.', data: const []);
    }
  }
}
