import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/utils/aqi_helper.dart';
import '../../../../common/utils/weather_code_helper.dart';
import '../../domain/entities/map_layer_type.dart';
import '../../domain/entities/station_entity.dart';
import '../cubits/map_state.dart';
import '../extensions/map_ui_extensions.dart';
import 'dropped_pin_marker_widget.dart';
import 'map_spot_markers.dart';
import 'station_marker_widget.dart';

/// Builds circle and marker overlays for MapPage outside the widget build tree.
class MapLayerBuilders {
  MapLayerBuilders._();

  static List<CircleMarker> buildCircles({
    required MapState state,
    required List<StationEntity> filteredStations,
    required LatLng? userGps,
    required double markerScale,
  }) {
    final circles = <CircleMarker>[];
    if (userGps != null) {
      circles.add(
        CircleMarker(
          point: userGps,
          radius: (35 * markerScale).clamp(20.0, 45.0),
          useRadiusInMeter: false,
          color: UIColors.gpsBlue.withValues(alpha: 0.12),
          borderColor: UIColors.gpsBlue.withValues(alpha: 0.4),
          borderStrokeWidth: 1.2,
        ),
      );
    }
    if (state.pickedLocation != null) {
      final pt = state.pickedLocation!;
      circles.addAll([
        CircleMarker(
          point: pt,
          radius: 38 * markerScale,
          useRadiusInMeter: false,
          color: UIColors.pinPurple.withValues(alpha: 0.18),
          borderColor: UIColors.pinPurple.withValues(alpha: 0.55),
          borderStrokeWidth: 1.5,
        ),
        CircleMarker(
          point: pt,
          radius: 18 * markerScale,
          useRadiusInMeter: false,
          color: UIColors.pinPurple.withValues(alpha: 0.32),
          borderColor: UIColors.transparent,
        ),
      ]);
    }
    if (state.showHeatmap) {
      for (final st in filteredStations) {
        final color = _layerCircleColor(st, state.activeLayer);
        final pt = LatLng(st.latitude, st.longitude);
        circles.addAll([
          CircleMarker(
            point: pt,
            radius: 46 * markerScale,
            useRadiusInMeter: false,
            color: color.withValues(alpha: 0.18),
            borderColor: color.withValues(alpha: 0.35),
            borderStrokeWidth: 1.5,
          ),
          CircleMarker(
            point: pt,
            radius: 24 * markerScale,
            useRadiusInMeter: false,
            color: color.withValues(alpha: 0.3),
            borderColor: UIColors.transparent,
          ),
        ]);
      }
    }
    return circles;
  }

  static Color _layerCircleColor(StationEntity st, MapLayerType layer) {
    return switch (layer) {
      MapLayerType.weather => WeatherCodeHelper.getInfo(st.weatherCode).color,
      MapLayerType.airQuality => AQIHelper.getAQIInfo(st.aqi).color,
      MapLayerType.thermal => st.heatRiskLevel.color,
      MapLayerType.flood =>
        st.isHighFloodRisk ? UIColors.markerRed : UIColors.gpsBlue,
    };
  }

  static List<Marker> buildMarkers({
    required MapState state,
    required List<StationEntity> filteredStations,
    required LatLng? userGps,
    required double markerScale,
    required ValueChanged<StationEntity> onSelectStation,
    required VoidCallback onTapGps,
    required ValueChanged<LatLng> onTapPickedPin,
  }) {
    final markers = filteredStations.map((st) {
      return Marker(
        point: LatLng(st.latitude, st.longitude),
        width: 80.0 * markerScale,
        height: 34.0 * markerScale,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.contain,
          child: StationMarkerWidget(
            station: st,
            isSelected: state.selectedStation?.id == st.id,
            activeLayer: state.activeLayer,
            onTap: () => onSelectStation(st),
          ),
        ),
      );
    }).toList();
    if (state.activeLayer == MapLayerType.thermal) {
      MapSpotMarkers.appendThermal(
        markers: markers,
        state: state,
        markerScale: markerScale,
        onSelectStation: onSelectStation,
      );
    } else if (state.activeLayer == MapLayerType.flood) {
      MapSpotMarkers.appendFlood(
        markers: markers,
        state: state,
        markerScale: markerScale,
        onSelectStation: onSelectStation,
      );
    }
    if (userGps != null) {
      markers.add(_buildGpsMarker(userGps, onTapGps));
    }
    if (state.pickedLocation != null) {
      final picked = state.pickedLocation!;
      markers.add(
        Marker(
          point: picked,
          width: 42.0 * markerScale,
          height: 42.0 * markerScale,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 42.0,
              height: 42.0,
              child: DroppedPinMarkerWidget(
                isLoading: state.isPickingLocation,
                onTap: () => onTapPickedPin(picked),
              ),
            ),
          ),
        ),
      );
    }
    MapSpotMarkers.appendArchipelagoLabels(
      markers: markers,
      markerScale: markerScale,
    );
    return markers;
  }

  static Marker _buildGpsMarker(LatLng userGps, VoidCallback onTapGps) {
    return Marker(
      point: userGps,
      width: 28,
      height: 28,
      child: GestureDetector(
        onTap: onTapGps,
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: UIColors.gpsBlue,
              shape: BoxShape.circle,
              border: Border.all(color: UIColors.white, width: 2.8),
              boxShadow: [
                BoxShadow(
                  color: UIColors.gpsBlue.withValues(alpha: 0.7),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: UIColors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
