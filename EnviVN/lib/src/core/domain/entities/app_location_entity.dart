import 'package:equatable/equatable.dart';
import 'enum/location_origin_type.dart';
import 'enum/popular_location.dart';

export 'enum/location_origin_type.dart';
export 'enum/popular_location.dart';

class AppLocationEntity extends Equatable {
  final String id;
  final String displayName;
  final String provinceOrRegion;
  final double latitude;
  final double longitude;
  final LocationOriginType originType;
  final double? distanceToNearestProvinceKm;
  final String? referenceProvinceName;

  const AppLocationEntity({
    required this.id,
    required this.displayName,
    required this.provinceOrRegion,
    required this.latitude,
    required this.longitude,
    this.originType = LocationOriginType.popularCity,
    this.distanceToNearestProvinceKm,
    this.referenceProvinceName,
  });

  String get name => displayName;
  String get province => provinceOrRegion;
  bool get isGps => originType == LocationOriginType.gps;
  bool get isCustomPin => originType == LocationOriginType.customMapPin;
  bool get isStation => originType == LocationOriginType.monitoringStation;

  String get formattedSubtitle {
    if (isCustomPin &&
        distanceToNearestProvinceKm != null &&
        referenceProvinceName != null) {
      final distStr = distanceToNearestProvinceKm! < 10.0
          ? distanceToNearestProvinceKm!.toStringAsFixed(1)
          : distanceToNearestProvinceKm!.toStringAsFixed(0);
      return 'Cách ~$distStr km từ $referenceProvinceName';
    }
    return provinceOrRegion;
  }

  factory AppLocationEntity.gps({
    required double latitude,
    required double longitude,
    String displayName = 'Vị trí hiện tại',
    String provinceOrRegion = 'Định vị GPS',
  }) {
    return AppLocationEntity(
      id: 'gps_current',
      displayName: displayName,
      provinceOrRegion: provinceOrRegion,
      latitude: latitude,
      longitude: longitude,
      originType: LocationOriginType.gps,
    );
  }

  factory AppLocationEntity.city({
    required String name,
    required String province,
    required double latitude,
    required double longitude,
    String? id,
    bool isGps = false,
  }) {
    return AppLocationEntity(
      id:
          id ??
          (isGps
              ? 'gps_saved'
              : 'city_${name.toLowerCase().replaceAll(' ', '_')}'),
      displayName: name,
      provinceOrRegion: province,
      latitude: latitude,
      longitude: longitude,
      originType: isGps
          ? LocationOriginType.gps
          : LocationOriginType.popularCity,
    );
  }

  factory AppLocationEntity.station({
    required String id,
    required String name,
    required String province,
    required double latitude,
    required double longitude,
    double? distanceKm,
  }) {
    return AppLocationEntity(
      id: 'station_$id',
      displayName: name,
      provinceOrRegion: province,
      latitude: latitude,
      longitude: longitude,
      originType: LocationOriginType.monitoringStation,
      distanceToNearestProvinceKm: distanceKm,
    );
  }

  factory AppLocationEntity.customPin({
    required double latitude,
    required double longitude,
    String? customName,
    String? referenceProvince,
    double? distanceKm,
  }) {
    final distStr = distanceKm != null
        ? (distanceKm < 10.0
              ? distanceKm.toStringAsFixed(1)
              : distanceKm.toStringAsFixed(0))
        : '';
    final name =
        customName ??
        (referenceProvince != null &&
                referenceProvince.isNotEmpty &&
                distStr.isNotEmpty
            ? 'Điểm ghim (~$distStr km từ $referenceProvince)'
            : 'Điểm ghim (${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)})');
    return AppLocationEntity(
      id: 'custom_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}',
      displayName: name,
      provinceOrRegion: referenceProvince ?? 'Tọa độ GPS',
      latitude: latitude,
      longitude: longitude,
      originType: LocationOriginType.customMapPin,
      distanceToNearestProvinceKm: distanceKm,
      referenceProvinceName: referenceProvince,
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'name': displayName,
    'province': provinceOrRegion,
    'lat': latitude,
    'lon': longitude,
    'originType': originType.name,
    if (distanceToNearestProvinceKm != null)
      'distanceKm': distanceToNearestProvinceKm,
    if (referenceProvinceName != null)
      'referenceProvince': referenceProvinceName,
  };

  /// Reconstructs full location metadata from storage JSON (compatible with legacy {name, lat, lon}).
  factory AppLocationEntity.fromStorageJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? defaultLocation.displayName;
    final lat =
        (json['lat'] as num?)?.toDouble() ??
        double.tryParse(json['lat']?.toString() ?? '') ??
        defaultLocation.latitude;
    final lon =
        (json['lon'] as num?)?.toDouble() ??
        double.tryParse(json['lon']?.toString() ?? '') ??
        defaultLocation.longitude;
    final rawOrigin = json['originType']?.toString();
    final parsedOrigin = rawOrigin != null
        ? LocationOriginType.values
              .where((o) => o.name == rawOrigin)
              .firstOrNull
        : null;
    if (parsedOrigin != null && json['id'] is String) {
      return AppLocationEntity(
        id: json['id'] as String,
        displayName: rawName,
        provinceOrRegion: json['province']?.toString() ?? rawName,
        latitude: lat,
        longitude: lon,
        originType: parsedOrigin,
        distanceToNearestProvinceKm: (json['distanceKm'] as num?)?.toDouble(),
        referenceProvinceName: json['referenceProvince']?.toString(),
      );
    }
    final normalizedName = rawName.startsWith('Vị trí hiện tại')
        ? 'Vị trí hiện tại'
        : rawName;
    if (rawName.startsWith('Điểm ghim')) {
      return AppLocationEntity.customPin(
        latitude: lat,
        longitude: lon,
        customName: rawName,
        referenceProvince: json['province']?.toString(),
      );
    }
    if (normalizedName == 'Vị trí hiện tại') {
      return AppLocationEntity.gps(latitude: lat, longitude: lon);
    }
    return AppLocationEntity.city(
      name: normalizedName,
      province: json['province']?.toString() ?? normalizedName,
      latitude: lat,
      longitude: lon,
    );
  }

  static const defaultLocation = AppLocationEntity(
    id: 'city_hanoi',
    displayName: 'Hà Nội',
    provinceOrRegion: 'Thủ đô Hà Nội',
    latitude: 21.0285,
    longitude: 105.8542,
    originType: LocationOriginType.popularCity,
  );

  static List<AppLocationEntity> get popularLocations =>
      PopularLocation.values.map((loc) => loc.toEntity()).toList();

  AppLocationEntity copyWith({
    String? id,
    String? displayName,
    String? provinceOrRegion,
    double? latitude,
    double? longitude,
    LocationOriginType? originType,
    double? distanceToNearestProvinceKm,
    bool clearDistance = false,
    String? referenceProvinceName,
    bool clearReferenceProvince = false,
  }) {
    return AppLocationEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      provinceOrRegion: provinceOrRegion ?? this.provinceOrRegion,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      originType: originType ?? this.originType,
      distanceToNearestProvinceKm: clearDistance
          ? null
          : (distanceToNearestProvinceKm ?? this.distanceToNearestProvinceKm),
      referenceProvinceName: clearReferenceProvince
          ? null
          : (referenceProvinceName ?? this.referenceProvinceName),
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    provinceOrRegion,
    latitude,
    longitude,
    originType,
    distanceToNearestProvinceKm,
    referenceProvinceName,
  ];
}

extension PopularLocationEntityX on PopularLocation {
  AppLocationEntity toEntity() {
    return AppLocationEntity(
      id: id,
      displayName: displayName,
      provinceOrRegion: provinceOrRegion,
      latitude: latitude,
      longitude: longitude,
      originType: LocationOriginType.popularCity,
    );
  }
}
