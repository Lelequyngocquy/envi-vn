import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/domain/entities/map_tile_config.dart';
import '../../domain/entities/station_entity.dart';
import '../cubits/map_state.dart';
import 'map_layer_builders.dart';

/// Renders the interactive FlutterMap canvas with isolated ValueListenable zoom layers.
class MapCanvasView extends StatelessWidget {
  final MapController mapController;
  final LatLngBounds vietnamBounds;
  final MapTileConfig tileConfig;
  final MapState state;
  final List<StationEntity> filteredStations;
  final LatLng? userGps;
  final ValueListenable<double> markerScaleListenable;
  final VoidCallback onMapReady;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<LatLng> onTapMap;
  final ValueChanged<StationEntity> onSelectStation;
  final VoidCallback onTapGps;
  final ValueChanged<LatLng> onTapPickedPin;

  const MapCanvasView({
    super.key,
    required this.mapController,
    required this.vietnamBounds,
    required this.tileConfig,
    required this.state,
    required this.filteredStations,
    required this.userGps,
    required this.markerScaleListenable,
    required this.onMapReady,
    required this.onZoomChanged,
    required this.onTapMap,
    required this.onSelectStation,
    required this.onTapGps,
    required this.onTapPickedPin,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        backgroundColor: UIColors.bg,
        initialCenter: state.targetLocation ?? const LatLng(16.0544, 108.2022),
        initialZoom: state.targetZoom ?? 5.8,
        minZoom: 4.6,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.containCenter(bounds: vietnamBounds),
        onMapReady: onMapReady,
        onPositionChanged: (camera, _) => onZoomChanged(camera.zoom),
        onTap: (_, point) {
          if (vietnamBounds.contains(point)) {
            onTapMap(point);
          }
        },
      ),
      children: [
        RepaintBoundary(
          child: TileLayer(
            urlTemplate: tileConfig.urlTemplate,
            userAgentPackageName: tileConfig.userAgentPackageName,
            tileBuilder: darkModeTileBuilder,
            tileBounds: vietnamBounds,
          ),
        ),
        PolygonLayer(
          invertedFill: UIColors.bg,
          polygons: [
            Polygon(
              points: [
                LatLng(vietnamBounds.south, vietnamBounds.west),
                LatLng(vietnamBounds.north, vietnamBounds.west),
                LatLng(vietnamBounds.north, vietnamBounds.east),
                LatLng(vietnamBounds.south, vietnamBounds.east),
              ],
              color: UIColors.transparent,
              borderColor: UIColors.cardGlassBorder,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        if (state.pickedLocation != null &&
            state.pickedReferenceLocation != null &&
            (state.pickedDistanceKm ?? 0) >= 0.5)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [state.pickedLocation!, state.pickedReferenceLocation!],
                strokeWidth: 2.2,
                color: UIColors.pinPurple.withValues(alpha: 0.8),
                pattern: StrokePattern.dashed(segments: const [6, 4]),
                borderStrokeWidth: 1.0,
                borderColor: UIColors.bg.withValues(alpha: 0.6),
              ),
            ],
          ),
        ValueListenableBuilder<double>(
          valueListenable: markerScaleListenable,
          builder: (_, scale, _) {
            final circles = MapLayerBuilders.buildCircles(
              state: state,
              filteredStations: filteredStations,
              userGps: userGps,
              markerScale: scale,
            );
            if (circles.isEmpty) {
              return const SizedBox.shrink();
            }
            return CircleLayer(circles: circles);
          },
        ),
        ValueListenableBuilder<double>(
          valueListenable: markerScaleListenable,
          builder: (_, scale, _) {
            final markers = MapLayerBuilders.buildMarkers(
              state: state,
              filteredStations: filteredStations,
              userGps: userGps,
              markerScale: scale,
              onSelectStation: onSelectStation,
              onTapGps: onTapGps,
              onTapPickedPin: onTapPickedPin,
            );
            return MarkerLayer(markers: markers);
          },
        ),
      ],
    );
  }
}
