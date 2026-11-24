import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/domain/entities/app_location_entity.dart';
import '../../../../core/presentation/cubits/app_location_cubit.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../domain/entities/map_layer_type.dart';
import '../cubits/map_cubit.dart';
import '../cubits/map_state.dart';
import 'map_side_controls.dart';
import 'map_top_control_bar.dart';
import 'map_zoom_controls.dart';
import 'station_preview_card.dart';

/// Floating UI controls and preview banners layered above FlutterMap.
class MapOverlaysLayer extends StatelessWidget {
  final MapState state;
  final AppLocationEntity currentLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onSelectHomeCity;
  final VoidCallback onMoveToCurrentGps;
  final VoidCallback onOpenLayerSelector;

  const MapOverlaysLayer({
    super.key,
    required this.state,
    required this.currentLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onSelectHomeCity,
    required this.onMoveToCurrentGps,
    required this.onOpenLayerSelector,
  });

  @override
  Widget build(BuildContext context) {
    final mapCubit = context.read<MapCubit>();
    return Stack(
      children: [
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: RepaintBoundary(
            child: MapTopControlBar(
              activeFilter: state.activeFilter,
              onFilterChanged: mapCubit.setFilter,
              showHeatmap: state.showHeatmap,
              onToggleHeatmap: mapCubit.toggleHeatmap,
              selectedCityName: state.selectedCityName,
              homeCityName: currentLocation.name,
              isHomeSelected: state.isHomeSelected,
              selectedQuickCity: state.selectedQuickCity,
              onSelectHomeCity: onSelectHomeCity,
              quickCities: state.quickCities,
              onSelectQuickCity: mapCubit.selectQuickCity,
              onSelectCity: mapCubit.selectLocationByCityName,
              onSelectAllVietnam: mapCubit.showAllVietnam,
            ),
          ),
        ),
        if (state.activeLayer == MapLayerType.thermal &&
            state.thermalNotice != null &&
            state.thermalNotice!.isNotEmpty)
          Positioned(
            top: 165,
            left: 20,
            right: 20,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: UIColors.bg.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          (state.isThermalFromCache
                                  ? UIColors.warning
                                  : UIColors.secondary)
                              .withValues(alpha: 0.6),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: UIColors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        state.isThermalFromCache
                            ? Icons.history_rounded
                            : Icons.satellite_alt_rounded,
                        size: 13,
                        color: state.isThermalFromCache
                            ? UIColors.warning
                            : UIColors.secondary,
                      ),
                      const Gap(5),
                      Flexible(
                        child: AppText.regular(
                          state.thermalNotice!,
                          size: 10.5,
                          color: UIColors.textPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: RepaintBoundary(
              child: MapZoomControls(onZoomIn: onZoomIn, onZoomOut: onZoomOut),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: RepaintBoundary(
              child: MapSideControls(
                hasPickedLocation: state.pickedLocation != null,
                onCancelPicker: () {
                  mapCubit.clearPickedLocation();
                  context.read<AppLocationCubit>().revertToGpsOrDefault();
                },
                onCurrentLocation: onMoveToCurrentGps,
                isHomeSelected: state.isHomeSelected,
                onToggleLayer: onOpenLayerSelector,
                activeLayer: state.activeLayer,
                onWholeCountry: mapCubit.showAllVietnam,
                isShowedAllVN: state.isShowedAllVN,
              ),
            ),
          ),
        ),
        if (state.selectedStation != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: RepaintBoundary(
              child: StationPreviewCard(
                station: state.selectedStation!,
                isLoading: state.isPickingLocation || state.isLoadingPointData,
                activeLayer: state.activeLayer,
                onClose: () {
                  mapCubit.clearSelection();
                  context.read<AppLocationCubit>().revertToGpsOrDefault();
                },
              ),
            ),
          ),
      ],
    );
  }
}
