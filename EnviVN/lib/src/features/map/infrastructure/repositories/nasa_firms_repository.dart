import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/domain/entities/base.dart';
import '../../../../core/infrastructure/configs/env_config.dart';
import '../../../../core/infrastructure/datasources/local/local_storage.dart';
import '../../domain/interfaces/i_nasa_firms_repository.dart';
import '../models/thermal_hotspot_model.dart';
import '../paths/nasa_firms_paths.dart';

class NasaFirmsRepository implements INasaFirmsRepository {
  final http.Client _client;
  final LocalStorage storage;
  final String? _apiKeyOverride;
  final String? _baseUrlOverride;

  NasaFirmsRepository({
    http.Client? client,
    required this.storage,
    String? apiKey,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _apiKeyOverride = apiKey,
       _baseUrlOverride = baseUrl;

  static const Duration cacheTtl = Duration(minutes: 15);
  static const Duration rateLimitCooldown = Duration(minutes: 10);

  DateTime? _lastRateLimitTime;
  Future<BaseResult<List<ThermalHotspotModel>>>? _activeFetchOperation;
  bool _isServingCachedData = false;

  @override
  bool get isServingCachedData => _isServingCachedData;

  @override
  DateTime? getLastUpdateTime() => storage.getThermalLastUpdateTime();

  @override
  Future<BaseResult<List<ThermalHotspotModel>>> getVietnamActiveFires({
    bool forceRefresh = false,
  }) {
    if (_activeFetchOperation != null) {
      return _activeFetchOperation!;
    }

    final future = _fetchInternal(forceRefresh: forceRefresh);
    _activeFetchOperation = future;

    return future.whenComplete(() {
      _activeFetchOperation = null;
    });
  }

  Future<BaseResult<List<ThermalHotspotModel>>> _fetchInternal({
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
        reason: 'Đang tạm dừng đợi hạn ngạch 10 phút của NASA FIRMS',
      );
    }

    final apiKey = _apiKeyOverride ?? EnvConfig.nasaFirmsMapKey;
    final baseUrl = _baseUrlOverride ?? EnvConfig.nasaFirmsBaseUrl;

    if (apiKey.isEmpty) {
      return _fallbackToStaleCache(reason: 'Chưa cấu hình NASA FIRMS MAP_KEY');
    }

    try {
      final result1Day = await _requestCsv(
        baseUrl: baseUrl,
        apiKey: apiKey,
        dayRange: 1,
      );

      if (result1Day.code == '429' || result1Day.code == '403') {
        return _fallbackToStaleCache(
          reason:
              result1Day.message ??
              'Đã chạm giới hạn hạn ngạch NASA (5000 lượt / 10 phút)',
        );
      }

      if (result1Day.isSuccess && (result1Day.data?.isNotEmpty ?? false)) {
        await _saveToStorage(result1Day.data!);
        _isServingCachedData = false;
        return BaseResult(
          data: result1Day.data,
          message: 'Vệ tinh NOAA-20 (VIIRS 375m) • Thời gian thực',
        );
      }

      final result2Days = await _requestCsv(
        baseUrl: baseUrl,
        apiKey: apiKey,
        dayRange: 2,
      );

      if (result2Days.code == '429' || result2Days.code == '403') {
        return _fallbackToStaleCache(
          reason:
              result2Days.message ??
              'Đã chạm giới hạn hạn ngạch NASA (5000 lượt / 10 phút)',
        );
      }

      if (result2Days.isSuccess && (result2Days.data?.isNotEmpty ?? false)) {
        await _saveToStorage(result2Days.data!);
        _isServingCachedData = false;
        return BaseResult(
          data: result2Days.data,
          message: 'Vệ tinh NOAA-20 (VIIRS 375m) • 48h qua',
        );
      }

      return _fallbackToStaleCache(
        reason: 'Vệ tinh không ghi nhận điểm nhiệt mới trong 48h qua',
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[NasaFirmsRepository] NASA FIRMS connection error');
      }
      return _fallbackToStaleCache(reason: 'Không thể kết nối máy chủ vệ tinh NASA FIRMS');
    }
  }

  Future<BaseResult<List<ThermalHotspotModel>>> _requestCsv({
    required String baseUrl,
    required String apiKey,
    required int dayRange,
  }) async {
    final url = NasaFirmsPaths.areaCsv(baseUrl: baseUrl, apiKey: apiKey, dayRange: dayRange);
    final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
    if (response.statusCode == 429) {
      _lastRateLimitTime = DateTime.now();
      return BaseResult(success: false, code: '429', message: 'Đã chạm giới hạn hạn ngạch NASA (5000 lượt / 10 phút), đang hiển thị dữ liệu lưu đệm.');
    }
    if (response.statusCode == 403) {
      return BaseResult(success: false, code: '403', message: 'Khóa xác thực NASA FIRMS không hợp lệ hoặc đã bị thu hồi.');
    }
    if (response.statusCode != 200) {
      return BaseResult(success: false, code: response.statusCode.toString(), message: 'Máy chủ NASA FIRMS phản hồi lỗi HTTP ${response.statusCode}.');
    }
    final csvText = response.body.trim();
    if (csvText.startsWith('Invalid') || csvText.isEmpty) {
      return BaseResult(success: false, code: '400', message: 'Dữ liệu điểm nhiệt vệ tinh không hợp lệ.');
    }
    final hotspots = ThermalHotspotModel.fromCsv(csvText);
    return BaseResult(data: hotspots);
  }

  BaseResult<List<ThermalHotspotModel>> _fallbackToStaleCache({
    required String reason,
  }) {
    final cached = _loadFromStorage();
    if (cached.isNotEmpty) {
      _isServingCachedData = true;
      final lastUpdate = storage.getThermalLastUpdateTime();
      final timeStr = lastUpdate != null ? 'lúc ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}' : '';
      return BaseResult(data: cached, message: 'Đang hiển thị dữ liệu vệ tinh lưu đệm $timeStr ($reason)');
    }
    // Never return fabricated active fire hotspots when no real cache exists.
    _isServingCachedData = false;
    return BaseResult(success: false, data: const [], message: 'Chưa có dữ liệu điểm nhiệt vệ tinh ($reason)');
  }

  List<ThermalHotspotModel> _loadFromStorage() {
    final rawList = storage.getCachedThermalHotspots();
    if (rawList == null || rawList.isEmpty) return [];
    try {
      return rawList.map((m) => ThermalHotspotModel.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToStorage(List<ThermalHotspotModel> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await storage.saveCachedThermalHotspots(jsonList);
  }
}
