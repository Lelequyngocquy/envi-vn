import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_status_tag.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

import 'hero_aqi_forecast_section.dart';

class HeroAQICard extends StatefulWidget {
  final AirQualityEntity airQuality;
  final String updateTimeText;
  final VoidCallback? onDetailTap;

  const HeroAQICard({
    super.key,
    required this.airQuality,
    this.updateTimeText = 'Cập nhật: Vừa xong',
    this.onDetailTap,
  });

  @override
  State<HeroAQICard> createState() => _HeroAQICardState();
}

class _HeroAQICardState extends State<HeroAQICard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasAqi = widget.airQuality.usAqi > 0;
    final hasHourly = widget.airQuality.hourlyAqi.isNotEmpty;
    final currentAqi = widget.airQuality.usAqi;
    final currentAqiInfo = hasAqi ? AQIHelper.getAQIInfo(currentAqi) : null;
    final pm25Text = widget.airQuality.pm25 > 0
        ? '${widget.airQuality.pm25.toStringAsFixed(1)} µg/m³'
        : '--';
    final pm10Text = widget.airQuality.pm10 > 0
        ? '${widget.airQuality.pm10.toStringAsFixed(1)} µg/m³'
        : '--';
    final statusColor = currentAqiInfo?.color ?? UIColors.textMuted;
    return AppGlass(
      borderRadius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AppText.bold(
                  'CHỈ SỐ CHẤT LƯỢNG KHÔNG KHÍ',
                  size: 11,
                  letterSpacing: 0.8,
                  color: UIColors.textSecondary,
                ),
              ),
              AppIcon(Icons.bubble_chart_rounded, color: statusColor, size: 20),
            ],
          ),
          const Gap(14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppText.extraBold(
                  hasAqi ? '$currentAqi' : '--',
                  size: 54,
                  color: UIColors.textPrimary,
                  height: 1.0,
                  maxLines: 3,
                ),
              ),
              const Gap(14),
              AppStatusTag(
                label: currentAqiInfo?.label ?? 'Chưa có dữ liệu',
                color: statusColor,
                size: AppTagSize.large,
              ),
            ],
          ),
          const Gap(12),
          AppText.medium(
            'PM2.5: $pm25Text  •  PM10: $pm10Text',
            size: 12,
            color: UIColors.textSecondary,
          ),
          const Gap(18),
          if (!hasHourly)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: AppText.regular(
                'Chưa có dữ liệu dự báo AQI theo giờ.',
                size: 12,
                color: UIColors.textMuted,
              ),
            )
          else
            HeroAqiForecastSection(
              airQuality: widget.airQuality,
              selectedIndex: _selectedIndex,
              referenceNow: DateTime.now(),
              onSelectIndex: (idx) => setState(() => _selectedIndex = idx),
            ),
          const Gap(14),
          const Divider(height: 1, color: UIColors.surfaceVariant),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.regular(
                widget.updateTimeText,
                size: 11,
                color: UIColors.textMuted,
              ),
              if (widget.onDetailTap != null)
                GestureDetector(
                  onTap: widget.onDetailTap,
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
}
