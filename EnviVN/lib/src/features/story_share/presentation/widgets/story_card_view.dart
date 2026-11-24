import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/common/utils/date_helper.dart';
import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

import '../models/story_models.dart';
import 'story_interactive_slot.dart';

/// Compact shareable environmental summary card supporting tile selection and swapping.
class StoryCardView extends StatelessWidget {
  final AppLocationEntity city;
  final AirQualityEntity airQuality;
  final DetailsEntity weather;
  final DateTime updateTime;
  final StoryRatio ratio;
  final List<StoryCardType> cards;
  final int? selectedIndex;
  final ValueChanged<int?>? onCardSelected;
  final void Function(int fromIndex, int toIndex)? onSwapCards;
  final bool isInteractive;

  const StoryCardView({
    super.key,
    required this.city,
    required this.airQuality,
    required this.weather,
    required this.updateTime,
    this.ratio = StoryRatio.story,
    this.cards = const [
      StoryCardType.airQuality,
      StoryCardType.weather,
      StoryCardType.floodRisk,
      StoryCardType.advisorHealth,
    ],
    this.selectedIndex,
    this.onCardSelected,
    this.onSwapCards,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final aqiInfo = AQIHelper.getAQIInfo(airQuality.usAqi);
    final weatherInfo = WeatherCodeHelper.getInfo(weather.weatherCode);
    final dateStr = DateHelper.formatVietnameseFull(updateTime);
    final timeStr = DateHelper.formatTime(updateTime);
    return AspectRatio(
      aspectRatio: ratio.ratioValue,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: UIColors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: aqiInfo.color.withValues(alpha: 0.22),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aqiInfo.color.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UIColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(timeStr),
                  const Gap(6),
                  _buildLocationRow(dateStr),
                  const Gap(8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: constraints.maxHeight - 20,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      child: _buildCardsGrid(
                                        aqiInfo: aqiInfo,
                                        weatherInfo: weatherInfo,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Gap(6),
                            _buildFooter(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String timeStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: UIColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const AppIcon(
                Icons.eco_rounded,
                color: UIColors.primary,
                size: 14,
              ),
            ),
            const Gap(6),
            const AppText.bold(
              'EnviVN',
              size: 13,
              color: UIColors.textPrimary,
              maxLines: 3,
            ),
          ],
        ),
        AppGlass(
          isFixed: false,
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: AppText.regular(
            timeStr,
            size: 10,
            color: UIColors.textSecondary,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String dateStr) {
    return Row(
      children: [
        AppIcon(
          city.isGps ? Icons.my_location_rounded : Icons.location_on_rounded,
          color: city.isGps ? UIColors.secondary : UIColors.primary,
          size: 14,
        ),
        const Gap(4),
        Expanded(
          child: AppText.bold(
            city.name,
            size: 15,
            color: UIColors.textPrimary,
            maxLines: 3,
          ),
        ),
        const Gap(6),
        AppText.regular(
          dateStr,
          size: 10,
          color: UIColors.textMuted,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Row(
      children: [
        Expanded(
          child: AppText.regular(
            'EnviVN • Giám sát môi trường',
            size: 8.5,
            color: UIColors.textMuted,
            maxLines: 3,
          ),
        ),
        Gap(4),
        AppText.regular(
          'envivn.app',
          size: 8.5,
          color: UIColors.textMuted,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCardsGrid({
    required AQIInfo aqiInfo,
    required WeatherCodeInfo weatherInfo,
  }) {
    if (cards.isEmpty) {
      return const Center(
        child: AppText.regular(
          'Chưa chọn thẻ dữ liệu nào',
          size: 12,
          color: UIColors.textMuted,
          maxLines: 3,
        ),
      );
    }
    final rowCount = (cards.length / 2).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowCount, (rowIndex) {
        final leftIndex = rowIndex * 2;
        final rightIndex = leftIndex + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rowCount - 1 ? 8 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StoryInteractiveSlot(
                    index: leftIndex,
                    totalCards: cards.length,
                    cardType: cards[leftIndex],
                    airQuality: airQuality,
                    weather: weather,
                    aqiInfo: aqiInfo,
                    weatherInfo: weatherInfo,
                    isInteractive: isInteractive,
                    isSelected: isInteractive && (selectedIndex == leftIndex),
                    onCardSelected: onCardSelected,
                    onSwapCards: onSwapCards,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: rightIndex < cards.length
                      ? StoryInteractiveSlot(
                          index: rightIndex,
                          totalCards: cards.length,
                          cardType: cards[rightIndex],
                          airQuality: airQuality,
                          weather: weather,
                          aqiInfo: aqiInfo,
                          weatherInfo: weatherInfo,
                          isInteractive: isInteractive,
                          isSelected:
                              isInteractive && (selectedIndex == rightIndex),
                          onCardSelected: onCardSelected,
                          onSwapCards: onSwapCards,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
