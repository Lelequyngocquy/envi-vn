import 'package:equatable/equatable.dart';

class LocationResult extends Equatable {
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

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    cityName,
    isDefault,
    isPermissionDenied,
    errorMessage,
  ];
}
