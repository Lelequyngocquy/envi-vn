import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/utils/heat_index_helper.dart';
import '../../domain/entities/map_layer_type.dart';
import '../../domain/entities/station_entity.dart';

extension MapLayerTypeUiX on MapLayerType {
  IconData get icon {
    switch (this) {
      case MapLayerType.weather:
        return Icons.wb_sunny_rounded;
      case MapLayerType.airQuality:
        return Icons.air_rounded;
      case MapLayerType.thermal:
        return Icons.local_fire_department_rounded;
      case MapLayerType.flood:
        return Icons.water_rounded;
    }
  }

  Color get badgeColor {
    switch (this) {
      case MapLayerType.weather:
        return UIColors.secondary;
      case MapLayerType.airQuality:
        return UIColors.primary;
      case MapLayerType.thermal:
        return UIColors.warning;
      case MapLayerType.flood:
        return UIColors.gpsBlue;
    }
  }
}

extension StationHeatUiX on StationEntity {
  HeatRiskLevel get heatRiskLevel =>
      HeatIndexHelper.getRiskLevel(calculatedHeatIndex);
}
