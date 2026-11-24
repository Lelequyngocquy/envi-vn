import 'package:equatable/equatable.dart';

import '../../domain/entities/app_location_entity.dart';

class AppLocationState extends Equatable {
  final AppLocationEntity currentLocation;
  final bool isLocationPermissionGranted;
  final bool isChangingLocation;
  final bool hasPendingMapSync;
  final String? noticeMessage;
  final DateTime? lastUpdated;

  const AppLocationState({
    this.currentLocation = AppLocationEntity.defaultLocation,
    this.isLocationPermissionGranted = false,
    this.isChangingLocation = false,
    this.hasPendingMapSync = true,
    this.noticeMessage,
    this.lastUpdated,
  });

  AppLocationState copyWith({
    AppLocationEntity? currentLocation,
    bool? isLocationPermissionGranted,
    bool? isChangingLocation,
    bool? hasPendingMapSync,
    String? noticeMessage,
    bool clearNotice = false,
    DateTime? lastUpdated,
  }) {
    return AppLocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationPermissionGranted:
          isLocationPermissionGranted ?? this.isLocationPermissionGranted,
      isChangingLocation: isChangingLocation ?? this.isChangingLocation,
      hasPendingMapSync: hasPendingMapSync ?? this.hasPendingMapSync,
      noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    currentLocation,
    isLocationPermissionGranted,
    isChangingLocation,
    hasPendingMapSync,
    noticeMessage,
    lastUpdated,
  ];
}
