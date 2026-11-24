import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/presentation/widgets/widgets.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

class Aqi24hChartCard extends StatelessWidget {
  final List<HourlyAqiPoint> hourlyPoints;

  const Aqi24hChartCard({super.key, required this.hourlyPoints});

  @override
  Widget build(BuildContext context) {
    return AppGlass(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bold(
                      'Diễn biến nồng độ 24 giờ qua',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      size: 16,
                      color: UIColors.textPrimary,
                    ),
                    Gap(4),
                    AppText.regular(
                      'Chỉ số AQI theo từng khung giờ',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      size: 12,
                      color: UIColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Gap(8),
              AppStatusTag(
                label: 'AQI US',
                color: UIColors.primary,
                size: AppTagSize.medium,
              ),
            ],
          ),
          const Gap(28),
          _build24hChart(hourlyPoints),
        ],
      ),
    );
  }

  Widget _build24hChart(List<HourlyAqiPoint> points) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: AppText.regular(
            'Chưa có dữ liệu diễn biến AQI 24 giờ',
            size: 12.5,
            color: UIColors.textMuted,
          ),
        ),
      );
    }
    final chartPoints = points.length > 24 ? points.sublist(0, 24) : points;
    final spots = List<FlSpot>.generate(
      chartPoints.length,
      (i) => FlSpot(i.toDouble(), chartPoints[i].aqi.toDouble()),
    );
    final rawMax = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final (maxY, interval) = _resolveYAxisScale(rawMax);
    final labelStep = chartPoints.length <= 6
        ? 1
        : (chartPoints.length / 4).round().clamp(1, 6);
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          minY: 0.0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: UIColors.border.withValues(alpha: 0.6),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: interval,
                getTitlesWidget: (val, _) => AppText.regular(
                  val.toInt().toString(),
                  color: UIColors.textMuted,
                  size: 10,
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (val, _) {
                  final idx = val.round();
                  if (idx < 0 || idx >= chartPoints.length) {
                    return const SizedBox.shrink();
                  }
                  final isEdge = idx == 0 || idx == chartPoints.length - 1;
                  final isTick =
                      idx % labelStep == 0 &&
                      (chartPoints.length - 1 - idx) >= (labelStep ~/ 2);
                  if (!isEdge && !isTick) return const SizedBox.shrink();
                  final hour = chartPoints[idx].time.hour.toString().padLeft(
                    2,
                    '0',
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AppText.regular(
                      '${hour}h',
                      color: UIColors.textSecondary,
                      size: 11,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: UIColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) {
                  final idx = spot.x.round();
                  return idx == 0 ||
                      idx == chartPoints.length - 1 ||
                      idx % labelStep == 0;
                },
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3.5,
                  color: UIColors.bg,
                  strokeWidth: 2.2,
                  strokeColor: UIColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    UIColors.primary.withValues(alpha: 0.35),
                    UIColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (double, double) _resolveYAxisScale(double rawMax) {
    if (rawMax <= 40) return (50.0, 10.0);
    if (rawMax <= 80) return (100.0, 25.0);
    if (rawMax <= 125) return (150.0, 50.0);
    if (rawMax <= 170) return (200.0, 50.0);
    if (rawMax <= 220) return (250.0, 50.0);
    if (rawMax <= 270) return (300.0, 50.0);
    if (rawMax <= 360) return (400.0, 100.0);
    return (((rawMax / 100).ceil() + 1) * 100.0, 100.0);
  }
}
