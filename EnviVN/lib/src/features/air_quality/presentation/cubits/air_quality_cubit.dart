import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/interfaces/i_air_quality_repository.dart';
import 'air_quality_state.dart';

class AirQualityCubit extends Cubit<AirQualityState> {
  final IAirQualityRepository repository;
  int _requestSeq = 0;

  AirQualityCubit({required this.repository}) : super(const AirQualityState()) {
    final cached = repository.getCachedAirQuality();
    if (cached != null) {
      emit(state.copyWith(status: AirQualityStatus.success, airQuality: cached, noticeMessage: 'Dữ liệu đã lưu ngoại tuyến'));
    }
  }

  Future<void> fetchAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final seq = ++_requestSeq;
    emit(state.copyWith(status: AirQualityStatus.loading, clearError: true));
    final result = await repository.getAirQuality(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh);
    if (isClosed || seq != _requestSeq) return;
    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(status: AirQualityStatus.success, airQuality: result.data, noticeMessage: result.message, clearNotice: result.message == null, clearError: true));
    } else {
      emit(state.copyWith(status: AirQualityStatus.failure, errorMessage: result.message ?? 'Không thể tải chỉ số chất lượng không khí'));
    }
  }

  Future<void> fetchForLocation(
    AppLocationEntity location, {
    bool forceRefresh = false,
  }) => fetchAirQuality(
    latitude: location.latitude,
    longitude: location.longitude,
    forceRefresh: forceRefresh,
  );
}
