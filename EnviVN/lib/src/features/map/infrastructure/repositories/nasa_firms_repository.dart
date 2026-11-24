import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/domain/entities/base.dart';
import '../../../../core/domain/entities/thermal_hotspot_entity.dart';
import '../../../../core/domain/interfaces/i_cache_store.dart';
import '../../../../core/infrastructure/configs/env_config.dart';
import '../../domain/interfaces/i_nasa_firms_repository.dart';
import '../models/thermal_hotspot_model.dart';
import '../paths/nasa_firms_paths.dart';

class NasaFirmsRepository implements INasaFirmsRepository {
  final http.Client _client;
  final bool _ownsClient;
  final ICacheStore storage;
  final String? _baseUrlOverride;

  NasaFirmsRepository({
    http.Client? client,
    required this.storage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _baseUrlOverride = baseUrl;

  void close() {
    if (_ownsClient) _client.close();
  }

  static const Duration cacheTtl = Duration(minutes: 15);
  static const Duration rateLimitCooldown = Duration(minutes: 10);

  DateTime? _lastRateLimitTime;
  Future<BaseResult<List<ThermalHotspotEntity>>>? _activeFetchOperation;
  bool _isServingCachedData = false;

  @override
  bool get isServingCachedData => _isServingCachedData;

  @override
  DateTime? getLastUpdateTime() => storage.getThermalLastUpdateTime();

  @override
  Future<BaseResult<List<ThermalHotspotEntity>>> getVietnamActiveFires({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _activeFetchOperation != null) {
      return _activeFetchOperation!;
    }
    final future = _fetchInternal(forceRefresh: forceRefresh);
    _activeFetchOperation = future;
    return future.whenComplete(() {
      if (identical(_activeFetchOperation, future)) {
        _activeFetchOperation = null;
      }
    });
  }

  Future<BaseResult<List<ThermalHotspotEntity>>> _fetchInternal({
    required bool forceRefresh,
  }) async {
    final now = DateTime.now();
    final lastUpdate = storage.getThermalLastUpdateTime();
    if (!forceRefresh &&
        lastUpdate != null &&
        now.difference(lastUpdate) < cacheTtl) {
      final cachedSpots = _loadFromStorage();
      if (cachedSpots.isNotEmpty) {
        _isServingCachedData = false;
        return BaseResult(
          data: cachedSpots,
          message: 'Vệ tinh NOAA-20 (VIIRS 375m) • Cập nhật gần đây',
        );
      }
    }
    if (_lastRateLimitTime != null &&
        now.difference(_lastRateLimitTime!) < rateLimitCooldown) {
      return _fallbackToStaleCache(
        reason: 'Đang tạm dừng do giới hạn tần suất truy cập máy chủ',
      );
    }
    final baseUrl = _baseUrlOverride ?? EnvConfig.backendBaseUrl;
    final apiKey = EnvConfig.clientApiKey;
    final uri = Uri.parse(
      '$baseUrl${NasaFirmsPaths.hotspots}',
    ).replace(queryParameters: {'force': forceRefresh.toString()});
    final headers = <String, String>{
      'Accept': 'application/json',
      if (apiKey.isNotEmpty) 'x-api-key': apiKey,
    };
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 429) {
        _lastRateLimitTime = DateTime.now();
        return _fallbackToStaleCache(
          reason: 'Đã chạm giới hạn tần suất truy cập máy chủ',
        );
      }
      if (response.statusCode != 200) {
        return _fallbackToStaleCache(
          reason: 'Máy chủ điểm nhiệt phản hồi lỗi HTTP ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['hotspots'] is! List) {
        return _fallbackToStaleCache(
          reason: 'Dữ liệu điểm nhiệt vệ tinh không hợp lệ',
        );
      }
      final hotspots = (decoded['hotspots'] as List)
          .whereType<Map>()
          .map(
            (m) =>
                ThermalHotspotModel.tryFromJson(Map<String, dynamic>.from(m)),
          )
          .whereType<ThermalHotspotModel>()
          .toList();
      if (hotspots.isNotEmpty) {
        await _saveToStorage(hotspots);
        _isServingCachedData = false;
        final source = decoded['source']?.toString() ?? '';
        final label = source.contains('48h')
            ? 'Vệ tinh NOAA-20 (VIIRS 375m) • 48h qua'
            : 'Vệ tinh NOAA-20 (VIIRS 375m) • Thời gian thực';
        return BaseResult(data: hotspots, message: label);
      }
      return _fallbackToStaleCache(
        reason: 'Vệ tinh không ghi nhận điểm nhiệt mới trong 48h qua',
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[NasaFirmsRepository] Backend hotspots request failed');
      }
      return _fallbackToStaleCache(
        reason: 'Không thể kết nối máy chủ điểm nhiệt vệ tinh',
      );
    }
  }

  BaseResult<List<ThermalHotspotEntity>> _fallbackToStaleCache({
    required String reason,
  }) {
    final cached = _loadFromStorage();
    if (cached.isNotEmpty) {
      _isServingCachedData = true;
      final lastUpdate = storage.getThermalLastUpdateTime();
      final timeStr = lastUpdate != null
          ? 'lúc ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}'
          : '';
      return BaseResult(
        data: cached,
        message: 'Đang hiển thị dữ liệu vệ tinh lưu đệm $timeStr ($reason)',
      );
    }
    _isServingCachedData = false;
    return BaseResult(
      success: false,
      data: const [],
      message: 'Chưa có dữ liệu điểm nhiệt vệ tinh ($reason)',
    );
  }

  List<ThermalHotspotModel> _loadFromStorage() {
    final rawList = storage.getCachedThermalHotspots();
    if (rawList == null || rawList.isEmpty) return [];
    try {
      return rawList
          .map(ThermalHotspotModel.tryFromJson)
          .whereType<ThermalHotspotModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToStorage(List<ThermalHotspotModel> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await storage.saveCachedThermalHotspots(jsonList);
  }
}
