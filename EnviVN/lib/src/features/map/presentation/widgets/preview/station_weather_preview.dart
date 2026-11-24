import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/utils/weather_code_helper.dart';
import '../../../../../core/presentation/widgets/app_icon.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../domain/entities/station_entity.dart';
import 'station_preview_shared.dart';

class StationWeatherPreview extends StatelessWidget {
  final StationEntity station;

  const StationWeatherPreview({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final weatherInfo = WeatherCodeHelper.getInfo(station.weatherCode);
    final temp = station.temperature ?? 28.0;
    final feelsLike = station.apparentTemp ?? (temp + 2.0);
    final rain = station.precipitation ?? 0.0;
    final humidity = station.humidity ?? 70;
    final wind = station.windSpeed ?? 10.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PreviewBadgeBox(
              color: weatherInfo.color,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(weatherInfo.icon, size: 22, color: weatherInfo.color),
                  const Gap(2),
                  AppText.extraBold(
                    '${temp.toStringAsFixed(0)}°C',
                    size: 14,
                    color: UIColors.textPrimary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.rich(
                    TextSpan(
                      text: weatherInfo.description,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: weatherInfo.color,
                      ),
                      children: [
                        TextSpan(
                          text: ' • Cảm giác ${feelsLike.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: UIColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      AppText.regular(
                        '🌧️ ${rain.toStringAsFixed(1)}mm',
                        size: 10.5,
                        color: UIColors.textSecondary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText.regular(
                        '💧 $humidity%',
                        size: 10.5,
                        color: UIColors.textSecondary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText.regular(
                        '💨 ${wind.toStringAsFixed(0)}km/h',
                        size: 10.5,
                        color: UIColors.textSecondary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(7),
        PreviewTipBanner(
          icon: rain > 0 ? Icons.umbrella_rounded : Icons.wb_sunny_outlined,
          color: weatherInfo.color,
          text: rain > 0
              ? 'Có mưa tại khu vực, hãy trang bị áo mưa và giữ khoảng cách an toàn khi lái xe.'
              : 'Thời tiết ổn định, thuận lợi cho các hoạt động di chuyển và sinh hoạt ngoài trời.',
        ),
      ],
    );
  }
}
