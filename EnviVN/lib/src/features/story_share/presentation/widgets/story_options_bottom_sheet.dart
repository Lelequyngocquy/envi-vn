import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/common/utils/weather_code_helper.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/presentation/widgets/app_bottom_sheet.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';
import 'package:envivn/src/shared/widgets/app_button.dart';
import 'package:envivn/src/shared/widgets/app_divider.dart';

import '../models/story_models.dart';
import 'story_mini_cards.dart';

export '../models/story_models.dart';

class StoryOptionsBottomSheet extends StatefulWidget {
  final StoryRatio initialRatio;
  final List<StoryCardType> initialCards;
  final AppLocationEntity city;
  final AirQualityEntity airQuality;
  final DetailsEntity weather;
  final void Function(StoryRatio ratio, List<StoryCardType> cards) onApply;

  const StoryOptionsBottomSheet({
    super.key,
    required this.initialRatio,
    required this.initialCards,
    required this.city,
    required this.airQuality,
    required this.weather,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required StoryRatio currentRatio,
    required List<StoryCardType> currentCards,
    required AppLocationEntity city,
    required AirQualityEntity airQuality,
    required DetailsEntity weather,
    required void Function(StoryRatio ratio, List<StoryCardType> cards) onApply,
  }) {
    return AppBottomSheet.show(
      context,
      title: 'Tùy chỉnh thẻ Story',
      subtitle: 'Tỷ lệ và các dữ liệu muốn chia sẻ',
      icon: Icons.settings_suggest,
      maxHeightFactor: 0.9,
      child: StoryOptionsBottomSheet(
        initialRatio: currentRatio,
        initialCards: currentCards,
        city: city,
        airQuality: airQuality,
        weather: weather,
        onApply: onApply,
      ),
    );
  }

  @override
  State<StoryOptionsBottomSheet> createState() =>
      _StoryOptionsBottomSheetState();
}

class _StoryOptionsBottomSheetState extends State<StoryOptionsBottomSheet> {
  late StoryRatio _selectedRatio;
  late List<StoryCardType> _selectedCards;

  @override
  void initState() {
    super.initState();
    _selectedRatio = widget.initialRatio;
    _selectedCards = List.from(widget.initialCards);
  }

  void _toggleCard(StoryCardType type) {
    setState(() {
      if (_selectedCards.contains(type)) {
        if (_selectedCards.length > 1) {
          _selectedCards.remove(type);
        }
      } else {
        _selectedCards.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aqiInfo = AQIHelper.getAQIInfo(widget.airQuality.usAqi);
    final weatherInfo = WeatherCodeHelper.getInfo(widget.weather.weatherCode);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppDivider(title: 'tỷ lệ khung hình'),
                const Gap(8),
                _buildRatioSelector(),
                const Gap(8),
                const AppDivider(title: 'các thẻ dữ liệu'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppText.semiBold(
                      'Đã chọn: ${_selectedCards.length}/${StoryCardMeta.all.length}',
                      size: 11,
                      color: UIColors.primary,
                      maxLines: 3,
                    ),
                  ],
                ),
                const Gap(10),
                ...StoryCardMeta.all.map(
                  (meta) => _buildCardOption(
                    meta,
                    aqiInfo: aqiInfo,
                    weatherInfo: weatherInfo,
                  ),
                ),
                const Gap(12),
              ],
            ),
          ),
        ),
        AppButton(
          onTap: () {
            widget.onApply(
              _selectedRatio,
              List<StoryCardType>.unmodifiable(_selectedCards),
            );
            Navigator.of(context).pop();
          },
          title: 'Áp dụng tùy chọn',
        ),
      ],
    );
  }

  Widget _buildRatioSelector() {
    return Row(
      children: StoryRatio.values.map((ratio) {
        final isSelected = _selectedRatio == ratio;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRatio = ratio),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? UIColors.primary.withValues(alpha: 0.18)
                      : UIColors.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? UIColors.primary
                        : UIColors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      ratio.icon,
                      size: 20,
                      color: isSelected
                          ? UIColors.primary
                          : UIColors.textSecondary,
                    ),
                    const Gap(4),
                    AppText.bold(
                      ratio.label,
                      size: 13,
                      color: isSelected
                          ? UIColors.primary
                          : UIColors.textPrimary,
                      maxLines: 3,
                    ),
                    const Gap(2),
                    AppText.regular(
                      ratio.description,
                      size: 10,
                      color: isSelected
                          ? UIColors.primaryDark
                          : UIColors.textMuted,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardOption(
    StoryCardMeta meta, {
    required AQIInfo aqiInfo,
    required WeatherCodeInfo weatherInfo,
  }) {
    final isChecked = _selectedCards.contains(meta.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _toggleCard(meta.type),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isChecked
                ? UIColors.primary.withValues(alpha: 0.08)
                : UIColors.cardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isChecked
                  ? UIColors.primary.withValues(alpha: 0.8)
                  : UIColors.white.withValues(alpha: 0.06),
              width: isChecked ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked
                          ? UIColors.primary
                          : UIColors.surfaceVariant,
                    ),
                    child: isChecked
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: UIColors.bg,
                          )
                        : null,
                  ),
                  const Gap(10),
                  AppIcon(meta.icon, size: 18, color: meta.iconColor),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bold(
                          meta.title,
                          size: 13,
                          color: UIColors.textPrimary,
                          maxLines: 3,
                        ),
                        AppText.regular(
                          meta.subtitle,
                          size: 10,
                          color: UIColors.textSecondary,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(8),
              StoryModuleTile(
                type: meta.type,
                airQuality: widget.airQuality,
                weather: widget.weather,
                aqiInfo: aqiInfo,
                weatherInfo: weatherInfo,
                isCompactPreview: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
