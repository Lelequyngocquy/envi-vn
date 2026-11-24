import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/widgets.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

class AqiPollutantsGrid extends StatelessWidget {
  final AirQualityEntity aqi;

  const AqiPollutantsGrid({super.key, required this.aqi});

  @override
  Widget build(BuildContext context) {
    final hasPm25 = aqi.pm25 > 0;
    final hasPm10 = aqi.pm10 > 0;
    final hasOzone = aqi.ozone > 0;
    final hasNo2 = aqi.nitrogenDioxide > 0;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _GlassPollutantCard(
          label: 'PM2.5',
          value: hasPm25 ? aqi.pm25.toStringAsFixed(1) : '--',
          unit: 'µg/m³',
          progress: hasPm25 ? (aqi.pm25 / 75.0).clamp(0.0, 1.0) : 0.0,
          progressColor: !hasPm25 ? UIColors.textMuted : (aqi.pm25 > 35 ? UIColors.aqiUnhealthySensitive : UIColors.aqiGood),
        ),
        _GlassPollutantCard(
          label: 'PM10',
          value: hasPm10 ? aqi.pm10.toStringAsFixed(1) : '--',
          unit: 'µg/m³',
          progress: hasPm10 ? (aqi.pm10 / 100.0).clamp(0.0, 1.0) : 0.0,
          progressColor: !hasPm10 ? UIColors.textMuted : (aqi.pm10 > 50 ? UIColors.aqiModerate : UIColors.aqiGood),
        ),
        _GlassPollutantCard(
          label: 'O₃ (Ozone)',
          value: hasOzone ? aqi.ozone.toStringAsFixed(1) : '--',
          unit: 'µg/m³',
          progress: hasOzone ? (aqi.ozone / 120.0).clamp(0.0, 1.0) : 0.0,
          progressColor: !hasOzone ? UIColors.textMuted : (aqi.ozone > 100 ? UIColors.aqiUnhealthySensitive : UIColors.secondary),
        ),
        _GlassPollutantCard(
          label: 'NO₂',
          value: hasNo2 ? aqi.nitrogenDioxide.toStringAsFixed(1) : '--',
          unit: 'µg/m³',
          progress: hasNo2 ? (aqi.nitrogenDioxide / 60.0).clamp(0.0, 1.0) : 0.0,
          progressColor: !hasNo2 ? UIColors.textMuted : (aqi.nitrogenDioxide > 40 ? UIColors.aqiModerate : UIColors.aqiGood),
        ),
      ],
    );
  }
}

class _GlassPollutantCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color progressColor;

  const _GlassPollutantCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlass(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.semiBold(label, size: 13, color: UIColors.textSecondary),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AppText.bold(value, size: 24, color: UIColors.textPrimary),
              const SizedBox(width: 4),
              AppText.regular(unit, size: 10, color: UIColors.textMuted),
            ],
          ),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: UIColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
