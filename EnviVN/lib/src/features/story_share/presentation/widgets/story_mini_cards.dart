import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/utils/aqi_helper.dart';
import '../../../../common/utils/weather_code_helper.dart';
import '../../../../core/domain/entities/air_quality_entity.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../shared/widgets/glass.dart';
import '../models/story_models.dart';
import 'story_activity_tiles.dart';

/// Shared strongly-typed modular tile used by both StoryCardView and StoryOptionsBottomSheet.
class StoryModuleTile extends StatelessWidget {
  final StoryCardType type;
  final AirQualityEntity airQuality;
  final DetailsEntity weather;
  final AQIInfo aqiInfo;
  final WeatherCodeInfo weatherInfo;
  final bool isCompactPreview;

  const StoryModuleTile({
    super.key,
    required this.type,
    required this.airQuality,
    required this.weather,
    required this.aqiInfo,
    required this.weatherInfo,
    this.isCompactPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = switch (type) {
      StoryCardType.airQuality => _buildAirQuality(),
      StoryCardType.weather => _buildWeather(),
      StoryCardType.floodRisk => _buildFloodRisk(),
      StoryCardType.advisorHealth => _buildAdvisorHealth(),
      StoryCardType.outdoorActivity => StoryTileHelpers.buildOutdoorActivity(
        airQuality: airQuality,
        weather: weather,
        weatherInfo: weatherInfo,
      ),
      StoryCardType.windAtmosphere => StoryTileHelpers.buildWindAtmosphere(
        weather,
      ),
    };
    return AppGlass(
      isFixed: false,
      borderRadius: isCompactPreview ? 12 : 16,
      padding: isCompactPreview
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: isCompactPreview
          ? child
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: child,
            ),
    );
  }

  Widget _buildAirQuality() {
    final aqi = airQuality.usAqi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StoryTileHelpers.buildHeader(
          Icons.air_rounded,
          UIColors.primary,
          'KHÔNG KHÍ',
          trailing: StoryTileHelpers.buildBadge(aqiInfo.label, aqiInfo.color),
        ),
        const Gap(4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText.bold('$aqi', size: 19, color: aqiInfo.color, maxLines: 3),
            const SizedBox(width: 4),
            const AppText.semiBold(
              'AQI US',
              size: 8.5,
              color: UIColors.textSecondary,
              maxLines: 3,
            ),
          ],
        ),
        const Gap(3),
        AppText.regular(
          'Bụi PM2.5: ${airQuality.pm25.toStringAsFixed(1)} µg/m³',
          size: 8.5,
          color: UIColors.textSecondary,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildWeather() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StoryTileHelpers.buildHeader(
          weatherInfo.icon,
          weatherInfo.color,
          'THỜI TIẾT',
          trailing: AppText.semiBold(
            'UV ${weather.uvIndex.toStringAsFixed(1)}',
            size: 8.5,
            color: UIColors.warning,
            maxLines: 3,
          ),
        ),
        const Gap(4),
        Row(
          children: [
            AppText.bold(
              '${weather.currentTemp.round()}°C',
              size: 17,
              color: UIColors.textPrimary,
              maxLines: 3,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AppText.semiBold(
                weatherInfo.description,
                size: 9,
                color: weatherInfo.color,
                maxLines: 3,
              ),
            ),
          ],
        ),
        const Gap(3),
        AppText.regular(
          'Cảm giác: ${weather.apparentTemp.round()}°C • Ẩm ${weather.relativeHumidity}%',
          size: 8.5,
          color: UIColors.textSecondary,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFloodRisk() {
    final isRaining = weather.precipitation > 0;
    final nextRainProb = weather.hourlyForecast.isNotEmpty
        ? weather.hourlyForecast.first.precipitationProbability
        : 0;
    final accent = isRaining || nextRainProb >= 50
        ? UIColors.warning
        : UIColors.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StoryTileHelpers.buildHeader(
          Icons.flood_rounded,
          UIColors.secondary,
          'NGẬP & MƯA',
          trailing: StoryTileHelpers.buildBadge(
            isRaining ? 'Có mưa' : '$nextRainProb%',
            accent,
          ),
        ),
        const Gap(4),
        AppText.bold(
          isRaining
              ? 'Mưa ${weather.precipitation.toStringAsFixed(1)} mm'
              : 'Khả năng mưa: $nextRainProb%',
          size: 11,
          color: isRaining || nextRainProb >= 50
              ? UIColors.warning
              : UIColors.textPrimary,
          maxLines: 3,
        ),
        const Gap(3),
        AppText.regular(
          isRaining || nextRainProb >= 60
              ? 'Đề phòng ngập cục bộ tại các điểm trũng'
              : 'Tuyến đường khô ráo, nguy cơ ngập thấp',
          size: 8.5,
          color: UIColors.textSecondary,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAdvisorHealth() {
    final highAqi = airQuality.usAqi > 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StoryTileHelpers.buildHeader(
          Icons.health_and_safety_rounded,
          UIColors.primaryDark,
          'CỐ VẤN Y TẾ',
        ),
        const Gap(4),
        AppText.bold(
          highAqi ? 'Khuyên dùng khẩu trang N95' : 'An toàn khi ra ngoài',
          size: 10.5,
          color: highAqi ? UIColors.warning : UIColors.primary,
          maxLines: 3,
        ),
        const Gap(3),
        AppText.regular(
          aqiInfo.healthAdvice,
          size: 8.5,
          color: UIColors.textSecondary,
          maxLines: 3,
        ),
      ],
    );
  }
}
