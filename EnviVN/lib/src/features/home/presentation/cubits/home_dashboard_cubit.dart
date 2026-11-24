import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/interfaces/i_cache_store.dart';
import 'package:envivn/src/core/domain/interfaces/i_location_service.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_cubit.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_state.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_cubit.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_state.dart';
import 'package:envivn/src/features/details/presentation/cubits/details_cubit.dart';
import 'package:envivn/src/features/details/presentation/cubits/details_state.dart';
import 'home_dashboard_state.dart';

class HomeDashboardCubit extends Cubit<HomeDashboardState> {
  final AppLocationCubit _locationCubit;
  final bool _ownsLocationCubit;
  final DetailsCubit detailsCubit;
  final AirQualityCubit airQualityCubit;
  StreamSubscription<AppLocationState>? _locationSub;
  AppLocationEntity _lastMirroredLocation = AppLocationEntity.defaultLocation;
  bool _suppressLocationFetch = false;
  int _fetchSeq = 0;

  HomeDashboardCubit({
    AppLocationCubit? appLocationCubit,
    ICacheStore? storage,
    ILocationService? locationService,
    required this.detailsCubit,
    required this.airQualityCubit,
  }) : assert(appLocationCubit != null || (storage != null && locationService != null)),
       _locationCubit = appLocationCubit ?? AppLocationCubit(cacheStore: storage!, locationService: locationService!),
       _ownsLocationCubit = appLocationCubit == null,
       super(const HomeDashboardState()) {
    _lastMirroredLocation = _locationCubit.state.currentLocation;
    _locationSub = _locationCubit.stream.listen(_onAppLocationChanged);
  }

  void _onAppLocationChanged(AppLocationState locState) {
    if (isClosed) return;
    final locationChanged = locState.currentLocation != _lastMirroredLocation;
    _lastMirroredLocation = locState.currentLocation;
    emit(
      state.copyWith(
        currentCity: locState.currentLocation,
        isLocationPermissionGranted: locState.isLocationPermissionGranted,
        isChangingLocation: locState.isChangingLocation,
        hasPendingMapSync: locState.hasPendingMapSync,
        noticeMessage: locState.noticeMessage,
        clearNotice: locState.noticeMessage == null,
        lastUpdated: locState.lastUpdated,
      ),
    );
    if (locationChanged && !_suppressLocationFetch) {
      _fetchDataForCity(locState.currentLocation);
    }
  }

  Future<void> initDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    _suppressLocationFetch = true;
    AppLocationEntity targetCity;
    try {
      targetCity = await _locationCubit.initLocation();
    } finally {
      _suppressLocationFetch = false;
    }
    if (isClosed) return;
    _lastMirroredLocation = targetCity;
    emit(
      state.copyWith(
        currentCity: targetCity,
        lastUpdated: _locationCubit.state.lastUpdated ?? DateTime.now(),
        isLocationPermissionGranted: _locationCubit.state.isLocationPermissionGranted,
      ),
    );
    await _fetchDataForCity(targetCity);
  }

  Future<void> changeCity(AppLocationEntity city) async {
    emit(state.copyWith(status: DashboardStatus.loading, isChangingLocation: true, currentCity: city, hasPendingMapSync: true, clearNotice: true));
    _suppressLocationFetch = true;
    try {
      await _locationCubit.selectLocation(city, syncToMap: true);
    } finally {
      _suppressLocationFetch = false;
    }
    if (isClosed) return;
    _lastMirroredLocation = city;
    await _fetchDataForCity(city);
  }

  Future<void> syncLocationFromMap(AppLocationEntity location) async {
    if (state.currentCity == location) return;
    emit(state.copyWith(status: DashboardStatus.loading, isChangingLocation: false, currentCity: location, hasPendingMapSync: false, clearNotice: true));
    _suppressLocationFetch = true;
    try {
      await _locationCubit.syncLocationFromMap(location);
    } finally {
      _suppressLocationFetch = false;
    }
    if (isClosed) return;
    _lastMirroredLocation = location;
    await _fetchDataForCity(location);
  }

  Future<void> detectGpsLocation() async {
    _suppressLocationFetch = true;
    AppLocationEntity? resolved;
    try {
      resolved = await _locationCubit.detectGpsLocation();
    } finally {
      _suppressLocationFetch = false;
    }
    if (isClosed || resolved == null) return;
    _lastMirroredLocation = resolved;
    await _fetchDataForCity(resolved);
  }

  Future<void> revertToGpsOrHome() async {
    final isGranted = await _locationCubit.locationService.checkPermissionGranted();
    if (isClosed) return;
    if (isGranted) {
      await detectGpsLocation();
    } else {
      await changeCity(AppLocationEntity.defaultLocation);
    }
  }

  void clearNotice() {
    _locationCubit.clearNotice();
    if (state.noticeMessage != null) {
      emit(state.copyWith(clearNotice: true));
    }
  }

  Future<void> refresh() async {
    await _fetchDataForCity(state.currentCity, forceRefresh: true);
  }

  Future<void> _fetchDataForCity(
    AppLocationEntity city, {
    bool forceRefresh = false,
  }) async {
    final seq = ++_fetchSeq;
    try {
      await Future.wait([
        detailsCubit.fetchForLocation(city, forceRefresh: forceRefresh),
        airQualityCubit.fetchForLocation(city, forceRefresh: forceRefresh),
      ]);
      if (isClosed || seq != _fetchSeq) return;
      final detailsFailed = detailsCubit.state.status == DetailsStatus.failure;
      final aqiFailed = airQualityCubit.state.status == AirQualityStatus.failure;
      if (detailsFailed && aqiFailed) {
        _locationCubit.failLocationChange('Không thể tải dữ liệu thời tiết và không khí. Vui lòng thử lại.');
        emit(state.copyWith(status: DashboardStatus.failure, isChangingLocation: false, noticeMessage: 'Không thể tải dữ liệu thời tiết và không khí. Vui lòng thử lại.'));
        return;
      }
      final aqi = airQualityCubit.state.airQuality.usAqi;
      final details = detailsCubit.state.details;
      final hasAlert = aqi > 100 || details.uvIndex >= 8 || (details.hourlyForecast.isNotEmpty && details.hourlyForecast.first.precipitationProbability >= 50);
      final now = DateTime.now();
      _locationCubit.finishLocationChange(updatedAt: now);
      emit(state.copyWith(status: DashboardStatus.success, isChangingLocation: false, lastUpdated: now, hasNotification: hasAlert));
    } catch (_) {
      if (isClosed || seq != _fetchSeq) return;
      _locationCubit.failLocationChange('Không thể tải dữ liệu vị trí mới. Vui lòng thử lại.');
      emit(state.copyWith(status: DashboardStatus.failure, isChangingLocation: false, noticeMessage: 'Không thể tải dữ liệu vị trí mới. Vui lòng thử lại.'));
    }
  }

  void setTab(int index) {
    if (state.currentTab != index) {
      emit(state.copyWith(currentTab: index));
      if (index == 3) {
        checkLocationPermissionStatus();
      }
    }
  }

  Future<void> checkLocationPermissionStatus() async {
    await _locationCubit.checkLocationPermissionStatus();
  }

  void markPendingMapSync() {
    _locationCubit.markPendingMapSync();
    if (!state.hasPendingMapSync) {
      emit(state.copyWith(hasPendingMapSync: true));
    }
  }

  void consumeMapSync() {
    _locationCubit.consumeMapSync();
    if (state.hasPendingMapSync) {
      emit(state.copyWith(hasPendingMapSync: false));
    }
  }

  bool handleBackPress() {
    if (state.currentTab != 0) {
      setTab(0);
      return true;
    }
    return false;
  }

  Future<void> requestLocationPermission({void Function()? onCompleted}) async {
    await detectGpsLocation();
    if (isClosed) return;
    if (state.isLocationPermissionGranted) {
      setTab(0);
      onCompleted?.call();
    }
  }

  Future<void> skipLocationPermission({void Function()? onCompleted}) async {
    final defaultCity = AppLocationEntity.defaultLocation;
    await _locationCubit.cacheStore.saveLocationPermission(false);
    await _locationCubit.cacheStore.saveSelectedLocation(defaultCity);
    if (isClosed) return;
    if (state.currentCity != defaultCity) {
      await changeCity(defaultCity);
    }
    if (isClosed) return;
    setTab(0);
    onCompleted?.call();
  }

  @override
  Future<void> close() async {
    await _locationSub?.cancel();
    if (_ownsLocationCubit) {
      await _locationCubit.close();
    }
    return super.close();
  }
}
