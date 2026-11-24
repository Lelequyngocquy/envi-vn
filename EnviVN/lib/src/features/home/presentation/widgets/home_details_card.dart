import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

import 'home_hourly_strip.dart';

class HomeDetailsCard extends StatelessWidget {
  final DetailsEntity details;
  final VoidCallback? onDetailTap;

  const HomeDetailsCard({super.key, required this.details, this.onDetailTap});

  @override
  Widget build(BuildContext context) {
    final weather = details;
    final weatherInfo = WeatherCodeHelper.getInfo(weather.weatherCode);
    final tempStr = weather.currentTemp.toStringAsFixed(0);
    final feelsLikeStr = weather.apparentTemp.toStringAsFixed(0);
    final isRaining = weather.precipitation > 0;
    final nextRainProb = weather.hourlyForecast.isNotEmpty
        ? weather.hourlyForecast.first.precipitationProbability
        : 0;
    final rainValue = isRaining
        ? '${weather.precipitation.toStringAsFixed(1)} mm'
        : '$nextRainProb%';
    final daily = weather.dailyForecast.isNotEmpty
        ? weather.dailyForecast.first
        : null;
    final highLowStr = daily != null
        ? 'Cao: ${daily.maxTemp.toStringAsFixed(0)}° • Thấp: ${daily.minTemp.toStringAsFixed(0)}°'
        : null;
    return AppGlass(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: AppText.bold(
                  'THỜI TIẾT HIỆN TẠI',
                  size: 11,
                  letterSpacing: 0.8,
                  color: UIColors.textSecondary,
                ),
              ),
              AppIcon(
                Icons.cloud_sync_rounded,
                size: 16,
                color: UIColors.secondary.withValues(alpha: 0.9),
              ),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.extraBold(
                          tempStr,
                          size: 50,
                          color: UIColors.textPrimary,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                        const Gap(4),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: AppText.bold(
                            '°C',
                            size: 22,
                            color: UIColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    AppText.bold(
                      weatherInfo.description,
                      size: 15,
                      color: weatherInfo.color,
                    ),
                    const Gap(4),
                    AppText.medium(
                      'Cảm giác như: $feelsLikeStr°C${highLowStr != null ? ' • $highLowStr' : ''}',
                      size: 12,
                      color: UIColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: weatherInfo.color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: weatherInfo.color.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: weatherInfo.color.withValues(alpha: 0.2),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AppIcon(
                  weatherInfo.icon,
                  size: 38,
                  color: weatherInfo.color,
                ),
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: UIColors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: UIColors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _WeatherPillItem(
                    icon: Icons.water_drop_rounded,
                    iconColor: UIColors.secondary,
                    label: isRaining ? 'Lượng mưa' : 'Khả năng mưa',
                    value: rainValue,
                  ),
                ),
                _divider(),
                Expanded(
                  child: _WeatherPillItem(
                    icon: Icons.air_rounded,
                    iconColor: UIColors.primary,
                    label: 'Tốc độ gió',
                    value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                  ),
                ),
                _divider(),
                Expanded(
                  child: _WeatherPillItem(
                    icon: Icons.opacity_rounded,
                    iconColor: UIColors.secondary,
                    label: 'Độ ẩm',
                    value: '${weather.relativeHumidity}%',
                  ),
                ),
                _divider(),
                Expanded(
                  child: _WeatherPillItem(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: UIColors.warning,
                    label: 'Chỉ số UV',
                    value: weather.uvIndex.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
          ),
          if (weather.hourlyForecast.isNotEmpty) ...[
            const Gap(14),
            HomeHourlyStrip(
              hourlyForecast: weather.hourlyForecast,
              onDetailTap: onDetailTap,
            ),
          ],
          const Gap(14),
          const Divider(height: 1, color: UIColors.surfaceVariant),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText.regular(
                'Cập nhật: Vừa xong',
                size: 11,
                color: UIColors.textMuted,
              ),
              if (onDetailTap != null)
                GestureDetector(
                  onTap: onDetailTap,
                  behavior: HitTestBehavior.opaque,
                  child: const Row(
                    children: [
                      AppText.bold(
                        'Chi tiết 24h',
                        size: 12,
                        color: UIColors.primary,
                      ),
                      AppIcon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: UIColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: UIColors.white.withValues(alpha: 0.08),
  );
}

class _WeatherPillItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _WeatherPillItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 14, color: iconColor),
        const Gap(3),
        AppText.bold(value, size: 12, color: UIColors.textPrimary, maxLines: 1),
        const Gap(1),
        AppText.medium(
          label,
          size: 9.5,
          color: UIColors.textSecondary,
          maxLines: 1,
        ),
      ],
    );
  }
}
