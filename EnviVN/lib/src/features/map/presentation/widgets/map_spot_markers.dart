import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/domain/entities/thermal_hotspot_entity.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../domain/entities/flood_blackspot.dart';
import '../../domain/entities/station_entity.dart';
import '../cubits/map_state.dart';

/// Builds thermal hotspot, flood blackspot, and archipelago sovereignty markers.
class MapSpotMarkers {
  MapSpotMarkers._();

  static const _archipelagos = [
    (
      name: 'Quần đảo Hoàng Sa',
      sovereignty: '(Việt Nam)',
      coords: LatLng(16.5333, 112.0333),
    ),
    (
      name: 'Quần đảo Trường Sa',
      sovereignty: '(Việt Nam)',
      coords: LatLng(9.8833, 114.2500),
    ),
  ];

  static void appendThermal({
    required List<Marker> markers,
    required MapState state,
    required double markerScale,
    required ValueChanged<StationEntity> onSelectStation,
  }) {
    final size = 46.0 * markerScale;
    for (final spot in state.thermalHotspots) {
      final isSelected = state.selectedStation?.id == spot.id;
      final isActive = spot.isActiveFire;
      final color = isActive ? UIColors.markerRedDark : UIColors.warning;
      final icon = isActive
          ? Icons.local_fire_department_rounded
          : Icons.whatshot_outlined;
      markers.add(
        _buildSpotMarker(
          point: LatLng(spot.latitude, spot.longitude),
          size: size,
          color: color,
          icon: icon,
          iconColor: isActive ? UIColors.white : UIColors.bg,
          iconSize: 20,
          isSelected: isSelected,
          isProminent: isActive,
          onTap: () => onSelectStation(_stationFromHotspot(spot)),
        ),
      );
    }
  }

  static void appendFlood({
    required List<Marker> markers,
    required MapState state,
    required double markerScale,
    required ValueChanged<StationEntity> onSelectStation,
  }) {
    final size = 46.0 * markerScale;
    for (final spot in FloodBlackspot.vietnamBlackspots) {
      final isSelected = state.selectedStation?.id == spot.id;
      markers.add(
        _buildSpotMarker(
          point: LatLng(spot.latitude, spot.longitude),
          size: size,
          color: UIColors.warning,
          icon: Icons.warning_amber_rounded,
          iconColor: UIColors.bg,
          iconSize: 21,
          isSelected: isSelected,
          isProminent: true,
          onTap: () => onSelectStation(_stationFromFloodSpot(spot)),
        ),
      );
    }
  }

  /// Renders archipelago sovereignty labels without BackdropFilter to avoid GPU readback jank.
  static void appendArchipelagoLabels({
    required List<Marker> markers,
    required double markerScale,
  }) {
    final labelW = (130.0 * markerScale).clamp(85.0, 140.0);
    final labelH = (38.0 * markerScale).clamp(26.0, 42.0);
    for (final item in _archipelagos) {
      markers.add(
        Marker(
          point: item.coords,
          width: labelW,
          height: labelH,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: UIColors.bg.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: UIColors.white.withValues(alpha: 0.2),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: UIColors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.bold(
                      item.name,
                      size: 10.5,
                      color: UIColors.textPrimary,
                      textAlign: TextAlign.center,
                    ),
                    const Gap(1),
                    AppText.semiBold(
                      item.sovereignty,
                      size: 8.5,
                      color: UIColors.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  static Marker _buildSpotMarker({
    required LatLng point,
    required double size,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required bool isSelected,
    required bool isProminent,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 46.0,
          height: 46.0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isSelected ? 0.95 : 0.82),
                border: Border.all(
                  color: isSelected ? UIColors.white : UIColors.cardBg,
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isProminent ? 0.7 : 0.45),
                    blurRadius: isSelected ? 12 : (isProminent ? 8 : 5),
                    spreadRadius: isProminent ? 1 : 0,
                  ),
                ],
              ),
              child: Center(
                child: AppIcon(icon, color: iconColor, size: iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static StationEntity _stationFromHotspot(ThermalHotspotEntity spot) {
    final isActive = spot.isActiveFire;
    return StationEntity(
      id: spot.id,
      name: spot.locationName,
      province: spot.province,
      latitude: spot.latitude,
      longitude: spot.longitude,
      aqi: isActive ? 165 : 45,
      pm25: isActive ? 85.0 : 15.0,
      pm10: isActive ? 110.0 : 25.0,
      updatedAt: DateTime.now(),
      isThermalHotspot: true,
      isActiveFire: isActive,
      fireType: spot.fireType,
      fireBrightnessCelsius: spot.brightnessCelsius,
      fireConfidence: spot.confidence,
      fireProneSeason: spot.proneSeason,
      fireDetectedTime: spot.detectedTime,
      spotDescription: spot.description,
      temperature: isActive ? spot.brightnessCelsius.clamp(38.0, 75.0) : null,
      apparentTemp: isActive ? spot.brightnessCelsius.clamp(42.0, 80.0) : null,
      weatherCode: isActive ? 1 : null,
      humidity: isActive ? 35 : null,
      windSpeed: isActive ? 16.0 : null,
      uvIndex: isActive ? 9.0 : null,
    );
  }

  static StationEntity _stationFromFloodSpot(FloodBlackspot spot) {
    return StationEntity(
      id: spot.id,
      name: spot.name,
      province: spot.province,
      latitude: spot.latitude,
      longitude: spot.longitude,
      aqi: 35,
      pm25: 10.0,
      pm10: 18.0,
      updatedAt: DateTime.now(),
      isFloodBlackspot: true,
      historicalDepthCm: spot.averageDepthCm,
      floodTriggerCondition: spot.triggerCondition,
      floodProneTime: spot.proneTime,
      spotDescription: spot.description,
    );
  }
}
