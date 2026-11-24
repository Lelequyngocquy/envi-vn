import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_cubit.dart';
import 'package:envivn/src/core/presentation/cubits/app_location_state.dart';
import 'package:envivn/src/core/presentation/widgets/widgets.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_cubit.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_state.dart';
import 'package:envivn/src/features/details/presentation/cubits/details_cubit.dart';
import 'package:envivn/src/features/details/presentation/cubits/details_state.dart';
import 'package:envivn/src/shared/widgets/app_button.dart';

import '../services/story_export_service.dart';
import '../widgets/story_card_view.dart';
import '../widgets/story_options_bottom_sheet.dart';

class StoryPreviewPage extends StatefulWidget {
  const StoryPreviewPage({super.key});

  @override
  State<StoryPreviewPage> createState() => _StoryPreviewPageState();
}

class _StoryPreviewPageState extends State<StoryPreviewPage> {
  final GlobalKey _cardKey = GlobalKey();
  final DateTime _previewTimestamp = DateTime.now();
  StoryRatio _ratio = StoryRatio.story;
  List<StoryCardType> _selectedCards = const [
    StoryCardType.airQuality,
    StoryCardType.weather,
    StoryCardType.floodRisk,
    StoryCardType.advisorHealth,
  ];
  int? _selectedCardIndex;
  bool _isSharing = false;

  void _handleSwapCards(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _selectedCards.length) return;
    if (toIndex < 0 || toIndex >= _selectedCards.length) return;
    final updated = List<StoryCardType>.from(_selectedCards);
    final temp = updated[fromIndex];
    updated[fromIndex] = updated[toIndex];
    updated[toIndex] = temp;
    setState(() {
      _selectedCards = updated;
      _selectedCardIndex = toIndex;
    });
  }

  Future<void> _handleShare(String cityName) async {
    if (_isSharing) return;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(1.5, 2.2);
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox != null
        ? (renderBox.localToGlobal(Offset.zero) & renderBox.size)
        : null;
    setState(() {
      _isSharing = true;
      _selectedCardIndex = null;
    });
    try {
      await StoryExportService.captureAndShare(
        boundaryKey: _cardKey,
        pixelRatio: pixelRatio,
        cityName: cityName,
        shareOrigin: shareOrigin,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: UIColors.error,
            content: AppText.semiBold(
              'Không thể tạo hoặc chia sẻ ảnh lúc này. Vui lòng thử lại.',
              size: 13,
              color: UIColors.white,
              maxLines: 3,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.bg,
      body: SafeArea(
        child: BlocBuilder<AppLocationCubit, AppLocationState>(
          buildWhen: (prev, curr) =>
              prev.currentLocation != curr.currentLocation,
          builder: (context, locationState) {
            return BlocBuilder<AirQualityCubit, AirQualityState>(
              buildWhen: (prev, curr) => prev.airQuality != curr.airQuality,
              builder: (context, aqiState) {
                return BlocBuilder<DetailsCubit, DetailsState>(
                  buildWhen: (prev, curr) => prev.details != curr.details,
                  builder: (context, detailsState) {
                    final city = locationState.currentLocation;
                    final aqi = aqiState.airQuality;
                    final weather = detailsState.details;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const AppBackButton(),
                              const Gap(12),
                              const Expanded(
                                child: AppText.bold(
                                  'Xem trước thẻ chia sẻ',
                                  size: 17,
                                  color: UIColors.textPrimary,
                                  maxLines: 3,
                                ),
                              ),
                              AppCircleButton(
                                icon: Icons.tune_rounded,
                                iconColor: UIColors.primary,
                                iconSize: 22,
                                tooltip: 'Tùy chọn hiển thị',
                                onTap: () {
                                  StoryOptionsBottomSheet.show(
                                    context,
                                    currentRatio: _ratio,
                                    currentCards: _selectedCards,
                                    city: city,
                                    airQuality: aqi,
                                    weather: weather,
                                    onApply: (newRatio, newCards) {
                                      setState(() {
                                        _ratio = newRatio;
                                        _selectedCards =
                                            List<StoryCardType>.from(newCards);
                                        _selectedCardIndex = null;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: _ratio == StoryRatio.story
                                            ? 320
                                            : (_ratio == StoryRatio.square
                                                  ? 360
                                                  : 340),
                                      ),
                                      child: RepaintBoundary(
                                        key: _cardKey,
                                        child: StoryCardView(
                                          city: city,
                                          airQuality: aqi,
                                          weather: weather,
                                          updateTime: _previewTimestamp,
                                          ratio: _ratio,
                                          cards: _selectedCards,
                                          selectedIndex: _selectedCardIndex,
                                          onCardSelected: (idx) => setState(
                                            () => _selectedCardIndex = idx,
                                          ),
                                          onSwapCards: _handleSwapCards,
                                          isInteractive: !_isSharing,
                                        ),
                                      ),
                                    ),
                                    const Gap(10),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AppIcon(
                                          Icons.touch_app_rounded,
                                          size: 13,
                                          color: UIColors.textMuted,
                                        ),
                                        Gap(4),
                                        AppText.regular(
                                          'Chạm vào thẻ để đổi vị trí',
                                          size: 11,
                                          color: UIColors.textMuted,
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AppButton(
                            title: 'Chia sẻ thẻ Story',
                            icon: Icons.ios_share_rounded,
                            isLoading: _isSharing,
                            onTap: () => _handleShare(city.name),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
