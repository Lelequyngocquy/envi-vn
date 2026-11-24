import 'dart:math' as math;

enum HeatRiskGrade { safe, caution, danger, extreme }

/// Pure Dart NOAA Rothfusz heat index calculator aligned with Backend Rust.
class HeatIndexCalculator {
  HeatIndexCalculator._();

  static double calculateHeatIndex(double tempC, int humidity) {
    if (tempC < 26.7) return tempC;
    final t = tempC * 9 / 5 + 32;
    final rh = humidity.toDouble();
    double hi = -42.379 + 2.04901523 * t + 10.14333127 * rh - 0.22475541 * t * rh - 0.00683783 * t * t - 0.05481717 * rh * rh + 0.00122874 * t * t * rh + 0.00085282 * t * rh * rh - 0.00000199 * t * t * rh * rh;
    if (rh < 13 && t >= 80 && t <= 112) {
      hi -= ((13 - rh) / 4) * math.sqrt((17 - (t - 95).abs()) / 17);
    } else if (rh > 85 && t >= 80 && t <= 87) {
      hi += ((rh - 85) / 10) * ((87 - t) / 5);
    }
    return (hi - 32) * 5 / 9;
  }

  static HeatRiskGrade getRiskGrade(double heatIndexC) {
    if (heatIndexC < 30.0) return HeatRiskGrade.safe;
    if (heatIndexC < 38.0) return HeatRiskGrade.caution;
    if (heatIndexC < 46.0) return HeatRiskGrade.danger;
    return HeatRiskGrade.extreme;
  }
}
