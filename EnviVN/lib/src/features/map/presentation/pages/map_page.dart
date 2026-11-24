import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/entities/map_tile_config.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_cubit.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_state.dart';
import 'package:envivn/src/core/presentation/widgets/loading.dart';
import 'package:envivn/src/features/map/domain/entities/map_layer_type.dart';
import 'package:envivn/src/features/map/presentation/cubits/map_cubit.dart';
import 'package:envivn/src/features/map/presentation/cubits/map_state.dart';
import 'package:envivn/src/features/map/presentation/widgets/map_canvas_view.dart';
import 'package:envivn/src/features/map/presentation/widgets/map_layer_selector_sheet.dart';
import 'package:envivn/src/features/map/presentation/widgets/map_overlays_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  final ValueNotifier<double> _markerScaleNotifier = ValueNotifier<double>(
    0.68,
  );
  bool _isMapReady = false;

  static final LatLngBounds _vietnamMapBounds = LatLngBounds(
    const LatLng(2.5, 101.8),
    const LatLng(24.0, 117.5),
  );

  double _calculateMarkerScale(double zoom) =>
      ((zoom - 4.6) / 6.4 * 0.48 + 0.52).clamp(0.52, 1.0);

  void _updateMarkerScaleIfNeeded(double zoom) {
    final nextScale = _calculateMarkerScale(zoom);
    if ((nextScale - _markerScaleNotifier.value).abs() >= 0.08) {
      _markerScaleNotifier.value = nextScale;
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMapState());
  }

  void _initMapState() {
    if (!mounted) {
      return;
    }
    final mapCubit = context.read<MapCubit>();
    final locationCubit = context.read<AppLocationCubit>();
    final effectiveCity = locationCubit.resolveInitialLocation();
    final isPermissionGranted = locationCubit.state.isLocationPermissionGranted;
    if (isPermissionGranted && effectiveCity.isGps) {
      mapCubit.setUserGpsLocation(
        LatLng(effectiveCity.latitude, effectiveCity.longitude),
      );
    } else {
      mapCubit.clearUserGpsLocation();
    }
    if (isPermissionGranted) {
      mapCubit.loadUserGpsLocation(
        fallbackCoords: effectiveCity.isGps
            ? LatLng(effectiveCity.latitude, effectiveCity.longitude)
            : null,
      );
    }
    if (mapCubit.state.stations.isEmpty) {
      final targetCityName =
          mapCubit.state.selectedCityName ?? effectiveCity.name;
      final targetCoords =
          mapCubit.state.targetLocation ??
          LatLng(effectiveCity.latitude, effectiveCity.longitude);
      mapCubit
          .fetchVietnamStations(
            initialCity: targetCityName,
            initialCoords: targetCoords,
          )
          .then(
            (_) => _applyInitialCamera(mapCubit, locationCubit, effectiveCity),
          );
    } else {
      _applyInitialCamera(mapCubit, locationCubit, effectiveCity);
    }
  }

  void _applyInitialCamera(
    MapCubit mapCubit,
    AppLocationCubit locationCubit,
    AppLocationEntity effectiveCity,
  ) {
    if (!mounted) {
      return;
    }
    if (mapCubit.state.targetLocation != null) {
      _safeMove(
        mapCubit.state.targetLocation!,
        mapCubit.state.targetZoom ?? 12.0,
      );
    } else if (locationCubit.state.hasPendingMapSync) {
      _syncWithHomeCity(effectiveCity);
      locationCubit.consumeMapSync();
    }
  }

  @override
  void dispose() {
    _markerScaleNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _syncWithHomeCity(AppLocationEntity city) {
    context.read<MapCubit>().selectHomeLocation(
      lat: city.latitude,
      lon: city.longitude,
      zoom: 12.0,
      label: city.name,
    );
    _safeMove(LatLng(city.latitude, city.longitude), 12.0);
  }

  Future<void> _moveToCurrentGpsLocation() async {
    final locationCubit = context.read<AppLocationCubit>();
    await locationCubit.detectGpsLocation();
    if (!mounted) {
      return;
    }
    _syncWithHomeCity(locationCubit.state.currentLocation);
  }

  MapTileConfig _resolveTileConfig(BuildContext context) {
    try {
      return context.read<MapTileConfig>();
    } catch (_) {
      return const MapTileConfig.defaults();
    }
  }

  void _safeMove(LatLng latLng, double zoom) {
    if (!_isMapReady || !mounted) {
      return;
    }
    try {
      _mapController.move(latLng, zoom);
      _updateMarkerScaleIfNeeded(zoom);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MapController.move] Skip move: $e');
      }
    }
  }

  void _zoomBy(double delta) {
    if (!_isMapReady) {
      return;
    }
    try {
      final minZ = delta > 0 ? 4.5 : 4.6;
      _safeMove(
        _mapController.camera.center,
        (_mapController.camera.zoom + delta).clamp(minZ, 18.0),
      );
    } catch (_) {}
  }

  void _openLayerSelector(BuildContext context, MapLayerType currentLayer) {
    MapLayerSelectorSheet.show(
      context,
      currentLayer: currentLayer,
      onLayerSelected: (newLayer) =>
          context.read<MapCubit>().switchMapLayer(newLayer),
    );
  }

  void _handleLocationSync(BuildContext context, AppLocationState locState) {
    final mapCubit = context.read<MapCubit>();
    if (!locState.isLocationPermissionGranted) {
      mapCubit.clearUserGpsLocation();
    } else if (locState.currentLocation.isGps) {
      mapCubit.setUserGpsLocation(
        LatLng(
          locState.currentLocation.latitude,
          locState.currentLocation.longitude,
        ),
      );
    }
    final hasActiveSelection =
        mapCubit.state.pickedLocation != null ||
        mapCubit.state.selectedStation != null;
    if (locState.hasPendingMapSync ||
        (mapCubit.state.isHomeSelected && !hasActiveSelection)) {
      _syncWithHomeCity(locState.currentLocation);
    }
    context.read<AppLocationCubit>().consumeMapSync();
  }

  void _handleMapSelectionSync(BuildContext context, MapState state) {
    if (state.targetLocation != null && state.targetZoom != null) {
      _safeMove(state.targetLocation!, state.targetZoom!);
    }
    final station = state.selectedStation;
    if (station != null && !state.isHomeSelected) {
      final isPicked = station.id.startsWith('picked_');
      final location = isPicked
          ? AppLocationEntity.customPin(
              latitude: station.latitude,
              longitude: station.longitude,
              customName: station.name,
              referenceProvince: station.province,
              distanceKm: state.pickedDistanceKm,
            )
          : AppLocationEntity.station(
              id: station.id,
              name: station.name,
              province: station.province,
              latitude: station.latitude,
              longitude: station.longitude,
            );
      context.read<AppLocationCubit>().syncLocationFromMap(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileConfig = _resolveTileConfig(context);
    return BlocListener<AppLocationCubit, AppLocationState>(
      listenWhen: (prev, curr) =>
          prev.currentLocation != curr.currentLocation ||
          prev.isLocationPermissionGranted !=
              curr.isLocationPermissionGranted ||
          (!prev.hasPendingMapSync && curr.hasPendingMapSync),
      listener: _handleLocationSync,
      child: Scaffold(
        backgroundColor: UIColors.bg,
        body: BlocBuilder<AppLocationCubit, AppLocationState>(
          buildWhen: (prev, curr) =>
              prev.currentLocation != curr.currentLocation ||
              prev.isLocationPermissionGranted !=
                  curr.isLocationPermissionGranted,
          builder: (context, locState) {
            return BlocConsumer<MapCubit, MapState>(
              listenWhen: (prev, curr) =>
                  (curr.targetLocation != null &&
                      (prev.targetLocation != curr.targetLocation ||
                          prev.targetZoom != curr.targetZoom)) ||
                  prev.selectedStation != curr.selectedStation,
              listener: _handleMapSelectionSync,
              builder: (context, state) {
                if (state.status == MapStatus.loading &&
                    state.stations.isEmpty) {
                  return const LoadingWidget(
                    message: 'Đang tải bản đồ & trạm quan trắc...',
                  );
                }
                final userGps = locState.isLocationPermissionGranted
                    ? (state.userGpsLocation ??
                          (locState.currentLocation.isGps
                              ? LatLng(
                                  locState.currentLocation.latitude,
                                  locState.currentLocation.longitude,
                                )
                              : null))
                    : null;
                return Stack(
                  children: [
                    MapCanvasView(
                      mapController: _mapController,
                      vietnamBounds: _vietnamMapBounds,
                      tileConfig: tileConfig,
                      state: state,
                      filteredStations: state.filteredStations,
                      userGps: userGps,
                      markerScaleListenable: _markerScaleNotifier,
                      onMapReady: () {
                        _isMapReady = true;
                        _updateMarkerScaleIfNeeded(_mapController.camera.zoom);
                        final cur = context.read<MapCubit>().state;
                        if (cur.targetLocation != null &&
                            cur.targetZoom != null) {
                          _safeMove(cur.targetLocation!, cur.targetZoom!);
                        }
                      },
                      onZoomChanged: _updateMarkerScaleIfNeeded,
                      onTapMap: (pt) =>
                          context.read<MapCubit>().pickCustomLocation(pt),
                      onSelectStation: (st) =>
                          context.read<MapCubit>().selectStation(st),
                      onTapGps: () =>
                          _syncWithHomeCity(locState.currentLocation),
                      onTapPickedPin: (pt) =>
                          context.read<MapCubit>().pickCustomLocation(pt),
                    ),
                    MapOverlaysLayer(
                      state: state,
                      currentLocation: locState.currentLocation,
                      onZoomIn: () => _zoomBy(1.0),
                      onZoomOut: () => _zoomBy(-1.0),
                      onSelectHomeCity: () =>
                          _syncWithHomeCity(locState.currentLocation),
                      onMoveToCurrentGps: _moveToCurrentGpsLocation,
                      onOpenLayerSelector: () =>
                          _openLayerSelector(context, state.activeLayer),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
