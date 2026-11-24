import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/utils/aqi_helper.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../domain/entities/station_entity.dart';
import 'station_preview_shared.dart';

class StationAqiPreview extends StatelessWidget {
  final StationEntity station;

  const StationAqiPreview({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final aqiInfo = AQIHelper.getAQIInfo(station.aqi);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PreviewBadgeBox(
              color: aqiInfo.color,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.extraBold(
                    '${station.aqi}',
                    size: 20,
                    color: aqiInfo.color,
                    height: 1.0,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  AppText.bold(
                    aqiInfo.label,
                    size: 9.5,
                    color: aqiInfo.color,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText.regular(
                          'Bụi mịn PM2.5',
                          size: 10,
                          color: UIColors.textSecondary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(1),
                        AppText.bold(
                          '${station.pm25.toStringAsFixed(1)} µg/m³',
                          size: 12.5,
                          color: UIColors.textPrimary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: UIColors.white.withValues(alpha: 0.1),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText.regular(
                          'Bụi thô PM10',
                          size: 10,
                          color: UIColors.textSecondary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(1),
                        AppText.bold(
                          '${station.pm10.toStringAsFixed(1)} µg/m³',
                          size: 12.5,
                          color: UIColors.textPrimary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(7),
        PreviewTipBanner(
          icon: aqiInfo.wearMask
              ? Icons.masks_rounded
              : Icons.check_circle_outline_rounded,
          color: aqiInfo.color,
          text: aqiInfo.healthAdvice,
        ),
      ],
    );
  }
}
