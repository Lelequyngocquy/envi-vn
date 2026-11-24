import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/utils/activity_advice_helper.dart';
import '../../../../common/utils/weather_code_helper.dart';
import '../../../../core/domain/entities/air_quality_entity.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';

/// Shared header and badge helpers plus outdoor/wind tiles for StoryModuleTile.
class StoryTileHelpers {
  StoryTileHelpers._();

  static Widget buildHeader(
    IconData icon,
    Color iconColor,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        AppIcon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: AppText.bold(
            title,
            size: 9,
            color: UIColors.textMuted,
            maxLines: 3,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing],
      ],
    );
  }

  static Widget buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText.bold(label, size: 8, color: color, maxLines: 3),
    );
  }

  static Widget buildOutdoorActivity({
    required AirQualityEntity airQuality,
    required DetailsEntity weather,
    required WeatherCodeInfo weatherInfo,
  }) {
    final rainProb = weather.hourlyForecast.isNotEmpty
        ? weather.hourlyForecast.first.precipitationProbability
        : 0;
    final advice = ActivityAdviceHelper.evaluate(
      aqi: airQuality.usAqi,
      uv: weather.uvIndex,
      rainProb: rainProb,
      hourlyWeather: weather.hourlyForecast,
      hourlyAqi: airQuality.hourlyAqi,
      isRaining: weather.precipitation > 0 || weatherInfo.isRain,
      precipitation: weather.precipitation,
    );
    final nextSlot = advice.slots.isNotEmpty ? advice.slots.first : null;
    final slotSubtitle = nextSlot != null
        ? 'UV ${weather.uvIndex.toStringAsFixed(1)} • ${nextSlot.timeRange}'
        : 'UV ${weather.uvIndex.toStringAsFixed(1)}';
    final headline = switch (advice.level) {
      ActivitySafetyLevel.safe => 'Thích hợp thể thao ngoài trời',
      ActivitySafetyLevel.caution => 'Chú ý khi vận động ngoài trời',
      ActivitySafetyLevel.avoid => 'Nên tập luyện trong nhà',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildHeader(
          Icons.directions_run_rounded,
          UIColors.pinPurple,
          'THỂ THAO',
          trailing: buildBadge(advice.statusLabel, advice.statusColor),
        ),
        const Gap(4),
        AppText.bold(
          headline,
          size: 10.5,
          color: advice.statusColor,
          maxLines: 3,
        ),
        const Gap(3),
        AppText.regular(
          slotSubtitle,
          size: 8.5,
          color: UIColors.textSecondary,
          maxLines: 3,
        ),
      ],
    );
  }

  static Widget buildWindAtmosphere(DetailsEntity weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildHeader(Icons.speed_rounded, UIColors.gpsBlue, 'GIÓ & KHÍ QUYỂN'),
        const Gap(4),
        Row(
          children: [
            Expanded(
              child: _buildMiniMetric(
                'Gió',
                '${weather.windSpeed.toStringAsFixed(1)} km/h',
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildMiniMetric(
                'Khí áp',
                '${weather.surfacePressure.toStringAsFixed(0)} hPa',
              ),
            ),
          ],
        ),
        const Gap(3),
        AppText.regular(
          weather.relativeHumidity > 80
              ? 'Độ ẩm cao (${weather.relativeHumidity}%), oi bức'
              : 'Độ ẩm ${weather.relativeHumidity}% • Khí áp ổn định',
          size: 8,
          color: UIColors.textSecondary,
          maxLines: 3,
        ),
      ],
    );
  }

  static Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.regular(
          label,
          size: 7.5,
          color: UIColors.textMuted,
          maxLines: 3,
        ),
        AppText.bold(
          value,
          size: 9.5,
          color: UIColors.textPrimary,
          maxLines: 3,
        ),
      ],
    );
  }
}
