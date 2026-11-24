import '../entities/location_result.dart';

/// Pure domain contract for GPS location & permission checks.
abstract class ILocationService {
  Future<bool> checkPermissionGranted();
  Future<LocationResult> getCurrentLocation();
}
