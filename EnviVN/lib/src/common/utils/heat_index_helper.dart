import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/domain/utils/heat_index_calculator.dart';

enum HeatRiskLevel {
  safe(
    label: 'An toàn',
    description: 'Nhiệt độ dễ chịu, không có nguy cơ sốc nhiệt.',
    color: UIColors.aqiGood,
    icon: Icons.sentiment_satisfied_rounded,
  ),
  caution(
    label: 'Cần thận trọng',
    description: 'Có thể mệt mỏi nếu tiếp xúc lâu hoặc vận động mạnh.',
    color: UIColors.aqiModerate,
    icon: Icons.info_outline_rounded,
  ),
  danger(
    label: 'Nguy cơ cao',
    description: 'Nguy cơ say nắng, chuột rút và kiệt sức vì nhiệt.',
    color: UIColors.aqiUnhealthySensitive,
    icon: Icons.warning_amber_rounded,
  ),
  extreme(
    label: 'Cực kỳ nguy hiểm',
    description: 'Nguy cơ đột quỵ nhiệt rất cao nếu ở lâu ngoài trời.',
    color: UIColors.markerRedDark,
    icon: Icons.local_fire_department_rounded,
  );

  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const HeatRiskLevel({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });
}

class HeatIndexHelper {
  HeatIndexHelper._();

  static double calculateHeatIndex(double tempC, int humidity) =>
      HeatIndexCalculator.calculateHeatIndex(tempC, humidity);

  static HeatRiskLevel getRiskLevel(double heatIndexC) {
    switch (HeatIndexCalculator.getRiskGrade(heatIndexC)) {
      case HeatRiskGrade.safe:
        return HeatRiskLevel.safe;
      case HeatRiskGrade.caution:
        return HeatRiskLevel.caution;
      case HeatRiskGrade.danger:
        return HeatRiskLevel.danger;
      case HeatRiskGrade.extreme:
        return HeatRiskLevel.extreme;
    }
  }

  static String getSunburnTimeAdvice(double uvIndex) {
    if (uvIndex < 3.0) return 'Trên 60 phút';
    if (uvIndex < 6.0) return 'Khoảng 45 phút';
    if (uvIndex < 8.0) return 'Khoảng 30 phút';
    if (uvIndex < 11.0) return 'Khoảng 15 - 20 phút';
    return 'Dưới 10 phút (Tránh ra nắng)';
  }
}
