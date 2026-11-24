import '../../../../core/domain/entities/thermal_hotspot_entity.dart';

/// Infrastructure DTO mapping Backend /api/v1/hotspots JSON to ThermalHotspotEntity.
class ThermalHotspotModel extends ThermalHotspotEntity {
  const ThermalHotspotModel({
    required super.id,
    required super.locationName,
    required super.province,
    required super.latitude,
    required super.longitude,
    required super.brightnessKelvin,
    required super.fireType,
    required super.confidence,
    required super.isActiveFire,
    required super.proneSeason,
    super.detectedTime,
    required super.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'locationName': locationName,
    'province': province,
    'latitude': latitude,
    'longitude': longitude,
    'brightnessKelvin': brightnessKelvin,
    'fireType': fireType,
    'confidence': confidence,
    'isActiveFire': isActiveFire,
    'proneSeason': proneSeason,
    'detectedTime': detectedTime,
    'description': description,
  };

  /// Parses Backend snake_case or cached camelCase JSON, returning null on invalid coordinates.
  static ThermalHotspotModel? tryFromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lon = (json['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null || !lat.isFinite || !lon.isFinite) {
      return null;
    }
    if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) return null;
    return ThermalHotspotModel(
      id: json['id']?.toString() ?? '',
      locationName:
          (json['location_name'] ?? json['locationName'])?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      latitude: lat,
      longitude: lon,
      brightnessKelvin:
          ((json['brightness_kelvin'] ?? json['brightnessKelvin']) as num?)
              ?.toDouble() ??
          300.0,
      fireType:
          (json['fire_type'] ?? json['fireType'])?.toString() ??
          'Điểm nhiệt vệ tinh',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 80.0,
      isActiveFire:
          (json['is_active_fire'] ?? json['isActiveFire']) as bool? ?? true,
      proneSeason:
          (json['prone_season'] ?? json['proneSeason'])?.toString() ?? '',
      detectedTime: (json['detected_time'] ?? json['detectedTime'])?.toString(),
      description: json['description']?.toString() ?? '',
    );
  }

  factory ThermalHotspotModel.fromJson(Map<String, dynamic> json) {
    return tryFromJson(json) ??
        ThermalHotspotModel(
          id: json['id']?.toString() ?? '',
          locationName:
              (json['location_name'] ?? json['locationName'])?.toString() ?? '',
          province: json['province']?.toString() ?? '',
          latitude: 0.0,
          longitude: 0.0,
          brightnessKelvin: 300.0,
          fireType: 'Điểm nhiệt vệ tinh',
          confidence: 80.0,
          isActiveFire: true,
          proneSeason: '',
          description: '',
        );
  }
}
