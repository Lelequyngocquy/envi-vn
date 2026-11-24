/// Satellite thermal anomaly / fire hotspot returned by Backend /api/v1/hotspots.
class ThermalHotspotModel {
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

  const ThermalHotspotModel({
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
    if (lat == null || lon == null || !lat.isFinite || !lon.isFinite) return null;
    if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) return null;
    return ThermalHotspotModel(
      id: json['id']?.toString() ?? '',
      locationName: (json['location_name'] ?? json['locationName'])?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      latitude: lat,
      longitude: lon,
      brightnessKelvin: ((json['brightness_kelvin'] ?? json['brightnessKelvin']) as num?)?.toDouble() ?? 300.0,
      fireType: (json['fire_type'] ?? json['fireType'])?.toString() ?? 'Điểm nhiệt vệ tinh',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 80.0,
      isActiveFire: (json['is_active_fire'] ?? json['isActiveFire']) as bool? ?? true,
      proneSeason: (json['prone_season'] ?? json['proneSeason'])?.toString() ?? '',
      detectedTime: (json['detected_time'] ?? json['detectedTime'])?.toString(),
      description: json['description']?.toString() ?? '',
    );
  }

  factory ThermalHotspotModel.fromJson(Map<String, dynamic> json) {
    return tryFromJson(json) ??
        ThermalHotspotModel(
          id: json['id']?.toString() ?? '',
          locationName: (json['location_name'] ?? json['locationName'])?.toString() ?? '',
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
