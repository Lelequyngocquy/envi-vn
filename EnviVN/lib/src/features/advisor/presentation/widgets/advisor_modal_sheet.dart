import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/utils/weather_code_helper.dart';
import '../../../../core/domain/entities/air_quality_entity.dart';
import '../../../../core/domain/entities/app_location_entity.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../../../core/domain/interfaces/i_ai_chat_service.dart';
import '../../../../core/presentation/widgets/app_bottom_sheet.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../cubits/advisor_chat_cubit.dart';
import '../cubits/advisor_chat_state.dart';
import '../cubits/advisor_cubit.dart';
import '../cubits/advisor_state.dart';
import 'advisor_result_card.dart';
import 'advisor_sheet_parts.dart';
import 'ai_chat_conversation_view.dart';
import 'outdoor_activity_advice_card.dart';

class AdvisorModalSheet extends StatelessWidget {
  final AirQualityEntity airQuality;
  final DetailsEntity weather;
  final String? cityName;
  final AppLocationEntity? location;
  final bool hasRespiratoryCondition;

  const AdvisorModalSheet({
    super.key,
    this.airQuality = const AirQualityEntity(),
    this.weather = const DetailsEntity(),
    this.cityName,
    this.location,
    this.hasRespiratoryCondition = false,
  });

  static Future<void> show(
    BuildContext context, {
    required AirQualityEntity airQuality,
    required DetailsEntity weather,
    String? cityName,
    AppLocationEntity? location,
    bool hasRespiratoryCondition = false,
  }) {
    final resolvedLocation = location ?? AppLocationEntity.defaultLocation;
    final chatService = context.read<IAiChatService>();
    return AppBottomSheet.show(
      context,
      title: 'Cố vấn Môi trường',
      subtitle: cityName != null && cityName.isNotEmpty
          ? 'Điều kiện thực tế tại $cityName chuẩn WHO & EPA'
          : 'Phân tích điều kiện tức thì theo chuẩn WHO & EPA',
      icon: Icons.wechat_sharp,
      maxHeightFactor: 0.92,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AdvisorCubit()),
          BlocProvider(
            create: (_) {
              final cubit = AdvisorChatCubit(inferenceService: chatService);
              cubit.initChat(location: resolvedLocation);
              return cubit;
            },
          ),
        ],
        child: AdvisorModalSheet(
          airQuality: airQuality,
          weather: weather,
          location: resolvedLocation,
          cityName: cityName,
          hasRespiratoryCondition: hasRespiratoryCondition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLocation = location ?? AppLocationEntity.defaultLocation;
    final aqi = airQuality.usAqi > 0 ? airQuality.usAqi : 50;
    final pm25 = airQuality.pm25;
    final temperature = weather.currentTemp;
    final uvIndex = weather.uvIndex;
    final weatherCode = weather.weatherCode;
    final precipitation = weather.precipitation;
    final weatherInfo = WeatherCodeHelper.getInfo(weatherCode);
    final isRaining = precipitation > 0.1 || weatherInfo.isRain;
    final rainProbability = weather.hourlyForecast.isNotEmpty
        ? weather.hourlyForecast.first.precipitationProbability
        : 0;
    return BlocBuilder<AdvisorChatCubit, AdvisorChatState>(
      buildWhen: (prev, curr) => prev.isAiEnabled != curr.isAiEnabled,
      builder: (context, chatState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdvisorModeToggleBar(
              isAiEnabled: chatState.isAiEnabled,
              onToggle: (enabled) =>
                  context.read<AdvisorChatCubit>().toggleAi(enabled),
            ),
            const Gap(12),
            if (chatState.isAiEnabled)
              Flexible(
                child: AiChatConversationView(
                  location: resolvedLocation,
                  weather: weather,
                  airQuality: airQuality,
                ),
              )
            else ...[
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutdoorActivityAdviceCard(
                        airQuality: airQuality,
                        weather: weather,
                        isCompact: true,
                      ),
                      _buildAdvisorDecisionSection(
                        aqi: aqi,
                        pm25: pm25,
                        temperature: temperature,
                        uvIndex: uvIndex,
                        isRaining: isRaining,
                        rainProbability: rainProbability,
                        precipitation: precipitation,
                        weatherCode: weatherCode,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              _buildPromptBar(
                aqi: aqi,
                pm25: pm25,
                temperature: temperature,
                uvIndex: uvIndex,
                isRaining: isRaining,
                rainProbability: rainProbability,
                precipitation: precipitation,
                weatherCode: weatherCode,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAdvisorDecisionSection({
    required int aqi,
    required double pm25,
    required double temperature,
    required double uvIndex,
    required bool isRaining,
    required int rainProbability,
    required double precipitation,
    required int weatherCode,
  }) {
    return BlocBuilder<AdvisorCubit, AdvisorState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.decision != curr.decision ||
          prev.selectedPrompt != curr.selectedPrompt,
      builder: (context, state) {
        if (state.status == AdvisorStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: UIColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        if (state.status == AdvisorStatus.success && state.decision != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AdvisorResultCard(
              decision: state.decision!,
              prompt: state.selectedPrompt,
              aqi: aqi,
              pm25: pm25,
              temperature: temperature,
              uvIndex: uvIndex,
              hasRespiratoryCondition: hasRespiratoryCondition,
              isRaining: isRaining,
              rainProbability: rainProbability,
              precipitation: precipitation,
              weatherCode: weatherCode,
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              AppIcon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color: UIColors.primary,
              ),
              Gap(6),
              Expanded(
                child: AppText.regular(
                  'Chạm vào câu hỏi gợi ý bên dưới để nhận phân tích chuyên sâu tức thì',
                  size: 11.5,
                  color: UIColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromptBar({
    required int aqi,
    required double pm25,
    required double temperature,
    required double uvIndex,
    required bool isRaining,
    required int rainProbability,
    required double precipitation,
    required int weatherCode,
  }) {
    return BlocBuilder<AdvisorCubit, AdvisorState>(
      buildWhen: (prev, curr) =>
          prev.selectedPrompt != curr.selectedPrompt ||
          prev.availablePrompts != curr.availablePrompts,
      builder: (context, state) {
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: state.availablePrompts.length,
            separatorBuilder: (_, _) => const Gap(8),
            itemBuilder: (context, index) {
              final prompt = state.availablePrompts[index];
              final isSelected = state.selectedPrompt == prompt;
              return AdvisorPromptChip(
                prompt: prompt,
                isSelected: isSelected,
                onTap: () {
                  if (isSelected) {
                    context.read<AdvisorCubit>().reset();
                  } else {
                    context.read<AdvisorCubit>().selectPrompt(
                      prompt,
                      aqi: aqi,
                      pm25: pm25,
                      temperature: temperature,
                      uvIndex: uvIndex,
                      hasRespiratoryCondition: hasRespiratoryCondition,
                      isRaining: isRaining,
                      rainProbability: rainProbability,
                      precipitation: precipitation,
                      weatherCode: weatherCode,
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
