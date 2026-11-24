import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';

import '../models/story_models.dart';
import 'story_mini_cards.dart';

/// Interactive wrapper around a StoryModuleTile providing selection highlight and 4-way swap controls.
class StoryInteractiveSlot extends StatelessWidget {
  final int index;
  final int totalCards;
  final StoryCardType cardType;
  final AirQualityEntity airQuality;
  final DetailsEntity weather;
  final AQIInfo aqiInfo;
  final WeatherCodeInfo weatherInfo;
  final bool isInteractive;
  final bool isSelected;
  final ValueChanged<int?>? onCardSelected;
  final void Function(int fromIndex, int toIndex)? onSwapCards;

  const StoryInteractiveSlot({
    super.key,
    required this.index,
    required this.totalCards,
    required this.cardType,
    required this.airQuality,
    required this.weather,
    required this.aqiInfo,
    required this.weatherInfo,
    required this.isInteractive,
    required this.isSelected,
    this.onCardSelected,
    this.onSwapCards,
  });

  @override
  Widget build(BuildContext context) {
    final col = index % 2;
    return GestureDetector(
      onTap: () {
        if (!isInteractive) {
          return;
        }
        onCardSelected?.call(isSelected ? null : index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? UIColors.primary
                : UIColors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: UIColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.loose,
          children: [
            StoryModuleTile(
              type: cardType,
              airQuality: airQuality,
              weather: weather,
              aqiInfo: aqiInfo,
              weatherInfo: weatherInfo,
            ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  color: UIColors.bg.withValues(alpha: 0.88),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildArrowButton(
                        icon: Icons.arrow_upward_rounded,
                        isEnabled: index - 2 >= 0,
                        onTap: () => onSwapCards?.call(index, index - 2),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildArrowButton(
                            icon: Icons.arrow_back_rounded,
                            isEnabled: col == 1,
                            onTap: () => onSwapCards?.call(index, index - 1),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: AppIcon(
                              Icons.open_with_rounded,
                              size: 13,
                              color: UIColors.primary,
                            ),
                          ),
                          _buildArrowButton(
                            icon: Icons.arrow_forward_rounded,
                            isEnabled: col == 0 && index + 1 < totalCards,
                            onTap: () => onSwapCards?.call(index, index + 1),
                          ),
                        ],
                      ),
                      _buildArrowButton(
                        icon: Icons.arrow_downward_rounded,
                        isEnabled: index + 2 < totalCards,
                        onTap: () => onSwapCards?.call(index, index + 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isEnabled
              ? UIColors.primary.withValues(alpha: 0.25)
              : UIColors.surfaceVariant.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled
                ? UIColors.primary
                : UIColors.white.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 13,
            color: isEnabled
                ? UIColors.primary
                : UIColors.textMuted.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
