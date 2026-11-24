import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/widgets.dart';
import 'package:envivn/src/features/map/domain/entities/map_layer_type.dart';
import 'package:envivn/src/features/map/domain/entities/station_entity.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

import 'preview/station_aqi_preview.dart';
import 'preview/station_flood_preview.dart';
import 'preview/station_preview_shared.dart';
import 'preview/station_thermal_preview.dart';
import 'preview/station_weather_preview.dart';

typedef LayerPreviewBuilder = Widget Function(StationEntity station);

class StationPreviewCard extends StatelessWidget {
  final StationEntity station;
  final VoidCallback onClose;
  final bool isLoading;
  final MapLayerType activeLayer;

  static final Map<MapLayerType, LayerPreviewBuilder> _layerRegistry = {
    MapLayerType.weather: (s) => StationWeatherPreview(station: s),
    MapLayerType.airQuality: (s) => StationAqiPreview(station: s),
    MapLayerType.thermal: (s) => StationThermalPreview(station: s),
    MapLayerType.flood: (s) => StationFloodPreview(station: s),
  };

  const StationPreviewCard({
    super.key,
    required this.station,
    required this.onClose,
    this.isLoading = false,
    this.activeLayer = MapLayerType.weather,
  });

  bool get _isContentLoading {
    if (!isLoading) return false;
    if (activeLayer == MapLayerType.airQuality &&
        !station.id.startsWith('picked_')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final builder =
        _layerRegistry[activeLayer] ?? _layerRegistry[MapLayerType.weather]!;
    return AppGlass(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Gap(8),
          if (_isContentLoading)
            PreviewLoadingContent(activeLayer: activeLayer)
          else
            builder(station),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isPicked = station.id.startsWith('picked_');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.rich(
                TextSpan(
                  text: station.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: UIColors.textPrimary,
                  ),
                  children: station.province.isNotEmpty
                      ? [
                          TextSpan(
                            text: ' • ${station.province}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: UIColors.textSecondary,
                            ),
                          ),
                        ]
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isPicked) ...[
                const Gap(2.5),
                Row(
                  children: [
                    const AppIcon(
                      Icons.gps_fixed_rounded,
                      size: 11,
                      color: UIColors.pinPurple,
                    ),
                    const Gap(4),
                    Expanded(
                      child: AppText.regular(
                        'Tọa độ: ${station.latitude.toStringAsFixed(4)}°B, ${station.longitude.toStringAsFixed(4)}°Đ',
                        color: UIColors.textSecondary,
                        size: 11,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (isLoading && !_isContentLoading)
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 2),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(UIColors.primary),
              ),
            ),
          ),
        const Gap(4),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: UIColors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              Icons.close_rounded,
              color: UIColors.textSecondary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
