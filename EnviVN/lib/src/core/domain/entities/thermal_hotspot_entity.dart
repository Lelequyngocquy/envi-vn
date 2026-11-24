import 'package:equatable/equatable.dart';

/// Pure domain entity representing a satellite thermal hotspot.
class ThermalHotspotEntity extends Equatable {
  final String id;
  final String locationName;
  final String province;
  final double latitude;
  final double longitude;
  final double brightnessKelvin;
  final String fireType;
  final double confidence;
  final bool isActiveFire;
  final String proneSeason;
  final String? detectedTime;
  final String description;

  const ThermalHotspotEntity({
    required this.id,
    required this.locationName,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.brightnessKelvin,
    required this.fireType,
    required this.confidence,
    required this.isActiveFire,
    required this.proneSeason,
    this.detectedTime,
    required this.description,
  });

  double get brightnessCelsius => brightnessKelvin - 273.15;

  @override
  List<Object?> get props => [
    id,
    locationName,
    province,
    latitude,
    longitude,
    brightnessKelvin,
    fireType,
    confidence,
    isActiveFire,
    proneSeason,
    detectedTime,
    description,
  ];
}
