import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';

/// Compact horizontal hourly weather strip shown inside HomeDetailsCard.
class HomeHourlyStrip extends StatelessWidget {
  final List<HourlyDetailsPoint> hourlyForecast;
  final VoidCallback? onDetailTap;

  const HomeHourlyStrip({
    super.key,
    required this.hourlyForecast,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpcomingRain = hourlyForecast.any(
      (h) => h.precipitationProbability >= 40,
    );
    final itemCount = hourlyForecast.length > 10 ? 10 : hourlyForecast.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText.bold(
              'DỰ BÁO CÁC GIỜ TIẾP THEO',
              size: 11,
              letterSpacing: 0.8,
              color: UIColors.textSecondary,
            ),
            if (hasUpcomingRain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: UIColors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      Icons.umbrella_rounded,
                      size: 11,
                      color: UIColors.secondary,
                    ),
                    Gap(4),
                    AppText.bold(
                      'Sắp có mưa',
                      size: 10,
                      color: UIColors.secondary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const Gap(10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const Gap(8),
            itemBuilder: (context, index) {
              final item = hourlyForecast[index];
              final isFirst = index == 0;
              final timeStr = isFirst
                  ? 'Bây giờ'
                  : DateFormat('HH:mm').format(item.time);
              final itemInfo = WeatherCodeHelper.getInfo(
                item.weatherCode,
                time: item.time,
              );
              return GestureDetector(
                onTap: onDetailTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFirst
                        ? UIColors.primary.withValues(alpha: 0.12)
                        : UIColors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFirst
                          ? UIColors.primary.withValues(alpha: 0.4)
                          : UIColors.white.withValues(alpha: 0.06),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        timeStr,
                        size: 11,
                        fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                        color: isFirst
                            ? UIColors.primary
                            : UIColors.textSecondary,
                      ),
                      AppIcon(itemInfo.icon, size: 18, color: itemInfo.color),
                      AppText.bold(
                        '${item.temperature.toStringAsFixed(0)}°',
                        size: 12,
                        color: UIColors.textPrimary,
                      ),
                      if (item.precipitationProbability > 0)
                        AppText.semiBold(
                          '${item.precipitationProbability}%',
                          size: 10,
                          color: UIColors.secondary,
                        )
                      else
                        const Gap(11),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
