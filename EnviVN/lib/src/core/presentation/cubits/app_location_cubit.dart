import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_location_entity.dart';
import '../../domain/interfaces/i_cache_store.dart';
import '../../domain/interfaces/i_location_service.dart';
import 'app_location_state.dart';

/// Shared SSOT Cubit managing active location, persistence, and GPS permissions across all features.
class AppLocationCubit extends Cubit<AppLocationState> {
  final ICacheStore cacheStore;
  final ILocationService locationService;

  AppLocationCubit({required this.cacheStore, required this.locationService})
    : super(const AppLocationState());

  bool get hasSavedLocation => cacheStore.getSelectedCity() != null;

  AppLocationEntity resolveInitialLocation() {
    if (state.currentLocation != AppLocationEntity.defaultLocation) {
      return state.currentLocation;
    }
    return cacheStore.getSelectedLocation() ?? state.currentLocation;
  }

  Future<AppLocationEntity> initLocation() async {
    AppLocationEntity target =
        cacheStore.getSelectedLocation() ?? AppLocationEntity.defaultLocation;
    final isGrantedInOs = await locationService.checkPermissionGranted();
    if (isClosed) return target;
    if (!isGrantedInOs && cacheStore.isLocationPermissionGranted()) {
      await cacheStore.saveLocationPermission(false);
    } else if (isGrantedInOs && !cacheStore.isLocationPermissionGranted()) {
      await cacheStore.saveLocationPermission(true);
    }
    if ((target.isGps || target.name.startsWith('Vị trí hiện tại')) &&
        !isGrantedInOs) {
      target = AppLocationEntity.defaultLocation;
      await cacheStore.saveSelectedLocation(target);
    }
    if (isClosed) return target;
    emit(
      state.copyWith(
        currentLocation: target,
        lastUpdated: cacheStore.getLastUpdateTime() ?? DateTime.now(),
        isLocationPermissionGranted: isGrantedInOs,
      ),
    );
    return target;
  }

  Future<void> selectLocation(
    AppLocationEntity location, {
    bool syncToMap = true,
  }) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        currentLocation: location,
        isChangingLocation: true,
        hasPendingMapSync: syncToMap,
        clearNotice: true,
      ),
    );
    try {
      await cacheStore.saveSelectedLocation(location);
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isChangingLocation: false,
          noticeMessage: 'Không thể lưu khu vực đã chọn.',
        ),
      );
    }
  }

  Future<void> syncLocationFromMap(AppLocationEntity location) async {
    if (isClosed || state.currentLocation == location) return;
    emit(
      state.copyWith(
        currentLocation: location,
        isChangingLocation: false,
        hasPendingMapSync: false,
        clearNotice: true,
      ),
    );
    try {
      await cacheStore.saveSelectedLocation(location);
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(noticeMessage: 'Không thể đồng bộ vị trí từ bản đồ.'),
      );
    }
  }

  Future<AppLocationEntity?> detectGpsLocation() async {
    try {
      final isGranted = await locationService.checkPermissionGranted();
      if (isClosed) return null;
      emit(
        state.copyWith(
          isChangingLocation: true,
          noticeMessage: isGranted ? null : 'Quyền truy cập vị trí đang bị tắt',
          clearNotice: isGranted,
        ),
      );
      final locationResult = await locationService.getCurrentLocation();
      if (isClosed) return null;
      if (locationResult.isDefault || locationResult.isPermissionDenied) {
        await cacheStore.saveLocationPermission(false);
        final defaultCity = AppLocationEntity.defaultLocation;
        await cacheStore.saveSelectedLocation(defaultCity);
        if (isClosed) return defaultCity;
        emit(
          state.copyWith(
            currentLocation: defaultCity,
            isLocationPermissionGranted: false,
            hasPendingMapSync: true,
            noticeMessage: locationResult.errorMessage,
            clearNotice: locationResult.errorMessage == null,
          ),
        );
        return defaultCity;
      }
      final gpsCity = AppLocationEntity.gps(
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        displayName: 'Vị trí hiện tại',
      );
      await cacheStore.saveLocationPermission(true);
      await cacheStore.saveSelectedLocation(gpsCity);
      if (isClosed) return gpsCity;
      emit(
        state.copyWith(
          currentLocation: gpsCity,
          isLocationPermissionGranted: true,
          hasPendingMapSync: true,
          clearNotice: true,
        ),
      );
      return gpsCity;
    } catch (_) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          isChangingLocation: false,
          noticeMessage: 'Không thể xác định vị trí GPS lúc này.',
        ),
      );
      return null;
    }
  }

  Future<void> revertToGpsOrDefault() async {
    final isGranted = await locationService.checkPermissionGranted();
    if (isClosed) return;
    if (isGranted) {
      await detectGpsLocation();
    } else {
      await selectLocation(AppLocationEntity.defaultLocation);
    }
  }

  Future<void> checkLocationPermissionStatus() async {
    final isGrantedInOs = await locationService.checkPermissionGranted();
    if (isClosed) return;
    if (!isGrantedInOs && cacheStore.isLocationPermissionGranted()) {
      await cacheStore.saveLocationPermission(false);
    } else if (isGrantedInOs && !cacheStore.isLocationPermissionGranted()) {
      await cacheStore.saveLocationPermission(true);
    }
    if (isClosed) return;
    if (isGrantedInOs != state.isLocationPermissionGranted) {
      emit(state.copyWith(isLocationPermissionGranted: isGrantedInOs));
    }
  }

  void finishLocationChange({DateTime? updatedAt}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isChangingLocation: false,
        lastUpdated: updatedAt ?? DateTime.now(),
      ),
    );
  }

  void failLocationChange(String message) {
    if (isClosed) return;
    emit(state.copyWith(isChangingLocation: false, noticeMessage: message));
  }

  void markPendingMapSync() {
    if (!isClosed && !state.hasPendingMapSync) {
      emit(state.copyWith(hasPendingMapSync: true));
    }
  }

  void consumeMapSync() {
    if (!isClosed && state.hasPendingMapSync) {
      emit(state.copyWith(hasPendingMapSync: false));
    }
  }

  void clearNotice() {
    if (!isClosed && state.noticeMessage != null) {
      emit(state.copyWith(clearNotice: true));
    }
  }
}
