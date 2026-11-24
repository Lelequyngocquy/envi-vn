import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? cityName;
  final bool isDefault;
  final bool isPermissionDenied;
  final String? errorMessage;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.isDefault = false,
    this.isPermissionDenied = false,
    this.errorMessage,
  });
}

class LocationService {
  static const double defaultLat = 21.0285;
  static const double defaultLon = 105.8542;
  static const Duration _lastKnownMaxAge = Duration(minutes: 15);

  Future<bool> checkPermissionGranted() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  Future<LocationResult> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return LocationResult(
          latitude: defaultLat,
          longitude: defaultLon,
          cityName: 'Hà Nội',
          isDefault: true,
          isPermissionDenied: true,
          errorMessage: permission == LocationPermission.deniedForever
              ? 'Quyền truy cập vị trí bị chặn. Vui lòng cấp quyền trong Cài đặt thiết bị.'
              : 'Quyền truy cập vị trí bị từ chối. Sử dụng vị trí mặc định (Hà Nội).',
        );
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          latitude: defaultLat,
          longitude: defaultLon,
          cityName: 'Hà Nội',
          isDefault: true,
          isPermissionDenied: false,
          errorMessage: 'Dịch vụ định vị GPS trên thiết bị đang tắt. Sử dụng vị trí mặc định (Hà Nội).',
        );
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && DateTime.now().difference(lastKnown.timestamp).abs() <= _lastKnownMaxAge) {
          return LocationResult(latitude: lastKnown.latitude, longitude: lastKnown.longitude, isDefault: false, isPermissionDenied: false);
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 5)),
        );
        return LocationResult(latitude: position.latitude, longitude: position.longitude, isDefault: false, isPermissionDenied: false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] GPS error or timeout: $e');
      }
    }
    return const LocationResult(
      latitude: defaultLat,
      longitude: defaultLon,
      cityName: 'Hà Nội',
      isDefault: true,
      isPermissionDenied: false,
      errorMessage: 'Không thể nhận diện vị trí GPS. Sử dụng vị trí mặc định (Hà Nội).',
    );
  }
}
