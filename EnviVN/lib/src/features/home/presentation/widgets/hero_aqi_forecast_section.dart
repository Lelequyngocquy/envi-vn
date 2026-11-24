import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';

/// Interactive 24-hour AQI bar timeline and milestone strip inside HeroAQICard.
class HeroAqiForecastSection extends StatelessWidget {
  final AirQualityEntity airQuality;
  final int selectedIndex;
  final DateTime referenceNow;
  final ValueChanged<int> onSelectIndex;

  const HeroAqiForecastSection({
    super.key,
    required this.airQuality,
    required this.selectedIndex,
    required this.referenceNow,
    required this.onSelectIndex,
  });

  DateTime _timeAt(int index) {
    if (airQuality.hourlyAqi.length > index) {
      return airQuality.hourlyAqi[index].time;
    }
    return referenceNow.add(Duration(hours: index));
  }

  int _aqiAt(int index) {
    if (airQuality.hourlyAqi.length > index) {
      return airQuality.hourlyAqi[index].aqi;
    }
    return airQuality.usAqi;
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatHour(DateTime t) => '${t.hour.toString().padLeft(2, '0')}h';

  @override
  Widget build(BuildContext context) {
    final maxIdx = airQuality.hourlyAqi.length - 1;
    final safeIdx = selectedIndex.clamp(0, maxIdx);
    final activeAqi = _aqiAt(safeIdx);
    final activeInfo = AQIHelper.getAQIInfo(activeAqi);
    final activeTime = _timeAt(safeIdx);
    final barCount = airQuality.hourlyAqi.length.clamp(1, 24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: activeInfo.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeInfo.color.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.bold(
                          safeIdx == 0
                              ? 'Hiện tại (${_formatTime(activeTime)})'
                              : '+${safeIdx}h (${_formatTime(activeTime)})',
                          size: 11,
                          color: UIColors.textPrimary,
                        ),
                        const Gap(2),
                        AppText.bold(
                          'AQI $activeAqi (${activeInfo.label})',
                          size: 11,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: activeInfo.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            GestureDetector(
              onTap: () {
                if (selectedIndex != 0) {
                  onSelectIndex(0);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AppText.regular(
                safeIdx == 0 ? 'Dự báo 24 giờ' : 'Về hiện tại',
                size: 11,
                color: safeIdx == 0 ? UIColors.textSecondary : UIColors.primary,
              ),
            ),
          ],
        ),
        const Gap(10),
        SizedBox(
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final isSelected = i == safeIdx;
              final isNow = i == 0;
              final aqi = _aqiAt(i);
              final info = AQIHelper.getAQIInfo(aqi);
              final factor = (aqi / 200).clamp(0.25, 1.0);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelectIndex(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1.2),
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      height: isSelected ? 34 * factor + 3 : 30 * factor,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? info.color
                            : info.color.withValues(alpha: isNow ? 0.95 : 0.75),
                        borderRadius: BorderRadius.circular(3),
                        border: isSelected
                            ? Border.all(color: UIColors.white, width: 1.4)
                            : (isNow
                                  ? Border.all(
                                      color: UIColors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      width: 0.8,
                                    )
                                  : null),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: info.color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Gap(8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMilestone(
              label: 'Hiện tại',
              timeText: _formatHour(_timeAt(0)),
              isHighlighted: safeIdx == 0,
              alignment: CrossAxisAlignment.start,
              onTap: () => onSelectIndex(0),
            ),
            _buildMilestone(
              label: '+6h',
              timeText: _formatHour(_timeAt(6.clamp(0, maxIdx))),
              isHighlighted: safeIdx == 6,
              alignment: CrossAxisAlignment.center,
              onTap: () => onSelectIndex(6.clamp(0, maxIdx)),
            ),
            _buildMilestone(
              label: '+12h',
              timeText: _formatHour(_timeAt(12.clamp(0, maxIdx))),
              isHighlighted: safeIdx == 12,
              alignment: CrossAxisAlignment.center,
              onTap: () => onSelectIndex(12.clamp(0, maxIdx)),
            ),
            _buildMilestone(
              label: '+18h',
              timeText: _formatHour(_timeAt(18.clamp(0, maxIdx))),
              isHighlighted: safeIdx == 18,
              alignment: CrossAxisAlignment.center,
              onTap: () => onSelectIndex(18.clamp(0, maxIdx)),
            ),
            _buildMilestone(
              label: '+23h',
              timeText: _formatHour(_timeAt(23.clamp(0, maxIdx))),
              isHighlighted: safeIdx == maxIdx && maxIdx > 0,
              alignment: CrossAxisAlignment.end,
              onTap: () => onSelectIndex(maxIdx),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestone({
    required String label,
    required String timeText,
    required bool isHighlighted,
    required CrossAxisAlignment alignment,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bold(
            timeText,
            size: 11,
            color: isHighlighted ? UIColors.primary : UIColors.textSecondary,
          ),
          const Gap(1),
          AppText.medium(
            label,
            size: 9.5,
            color: isHighlighted ? UIColors.primary : UIColors.textMuted,
          ),
        ],
      ),
    );
  }
}
