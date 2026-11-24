import 'package:latlong2/latlong.dart';

import '../../../../common/utils/geo_distance_helper.dart';
import '../../../../core/domain/entities/app_location_entity.dart';
import '../entities/quick_city_target.dart';
import '../entities/station_entity.dart';
import '../entities/vietnam_province.dart';

/// Pure domain spatial resolver supporting MapCubit station/city/pin queries.
class MapLocationResolver {
  MapLocationResolver._();

  static ({StationEntity? station, double distanceKm}) findClosestStation(
    List<StationEntity> stations,
    double lat,
    double lon,
  ) {
    StationEntity? closestStation;
    double minDistance = double.infinity;
    for (final st in stations) {
      final d = GeoDistanceHelper.distanceInKm(
        lat,
        lon,
        st.latitude,
        st.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        closestStation = st;
      }
    }
    return (station: closestStation, distanceKm: minDistance);
  }

  static StationEntity? findStationByCityName(
    List<StationEntity> stations,
    String cityName,
  ) {
    final normQuery = GeoDistanceHelper.normalizeName(cityName);
    for (final st in stations) {
      final normProvince = GeoDistanceHelper.normalizeName(st.province);
      final normName = GeoDistanceHelper.normalizeName(st.name);
      if (normProvince.contains(normQuery) ||
          normQuery.contains(normProvince) ||
          normName.contains(normQuery) ||
          normQuery.contains(normName)) {
        return st;
      }
    }
    return null;
  }

  static LatLng? getCityCoordinates(String cityName) {
    final target = QuickCityTarget.findByQuery(cityName);
    if (target != null) return LatLng(target.latitude, target.longitude);
    final norm = GeoDistanceHelper.normalizeName(cityName);
    for (final city in AppLocationEntity.popularLocations) {
      final normCity = GeoDistanceHelper.normalizeName(city.name);
      if (normCity.contains(norm) || norm.contains(normCity)) {
        return LatLng(city.latitude, city.longitude);
      }
    }
    for (final prov in VietnamProvince.values) {
      final normProv = GeoDistanceHelper.normalizeName(prov.provinceName);
      if (normProv.contains(norm) || norm.contains(normProv)) {
        return LatLng(prov.latitude, prov.longitude);
      }
    }
    return null;
  }

  static ({
    String name,
    String province,
    LatLng? referenceCoords,
    double distanceKm,
  })
  resolvePickedMeta({
    required LatLng point,
    required List<StationEntity> stations,
    required List<QuickCityTarget> quickCities,
    String? customName,
    String? customProvince,
  }) {
    final closest = findClosestStation(
      stations,
      point.latitude,
      point.longitude,
    );
    final closestStation = closest.station;
    double minDistance = closest.distanceKm;
    String province = customProvince ?? (closestStation?.province ?? '');
    LatLng? referenceCoords = closestStation != null
        ? LatLng(closestStation.latitude, closestStation.longitude)
        : null;
    if (province.isEmpty) {
      QuickCityTarget? closestCity;
      for (final city in quickCities) {
        if (city.isAllCountry) continue;
        final d = GeoDistanceHelper.distanceInKm(
          point.latitude,
          point.longitude,
          city.latitude,
          city.longitude,
        );
        if (d < minDistance) {
          minDistance = d;
          closestCity = city;
        }
      }
      if (closestCity != null) {
        province = closestCity.label;
        referenceCoords = LatLng(closestCity.latitude, closestCity.longitude);
      } else {
        final prov = VietnamProvince.findClosest(
          point.latitude,
          point.longitude,
        );
        province = prov.province.provinceName;
        minDistance = prov.distanceKm;
        referenceCoords = LatLng(
          prov.province.latitude,
          prov.province.longitude,
        );
      }
    }
    if (province.isEmpty) province = 'Tọa độ GPS';
    final distStr = GeoDistanceHelper.formatDistance(minDistance);
    final name =
        customName ??
        (minDistance.isFinite && distStr.isNotEmpty
            ? 'Điểm ghim ($distStr từ $province)'
            : 'Điểm ghim (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})');
    return (
      name: name,
      province: province,
      referenceCoords: referenceCoords,
      distanceKm: minDistance,
    );
  }
}
