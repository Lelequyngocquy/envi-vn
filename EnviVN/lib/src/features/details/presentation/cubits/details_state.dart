import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../domain/entities/detail_tab.dart';

enum DetailsStatus { initial, loading, success, failure }

class DetailsState extends Equatable {
  final DetailsStatus status;
  final DetailsEntity details;
  final String? errorMessage;
  final String? noticeMessage;
  final DetailTab activeDetailTab;

  const DetailsState({
    this.status = DetailsStatus.initial,
    this.details = const DetailsEntity(),
    this.errorMessage,
    this.noticeMessage,
    this.activeDetailTab = DetailTab.all,
  });

  bool get showWeatherSection =>
      activeDetailTab == DetailTab.all || activeDetailTab == DetailTab.weather;

  bool get showAirQualitySection =>
      activeDetailTab == DetailTab.all ||
      activeDetailTab == DetailTab.airQuality;

  DetailsState copyWith({
    DetailsStatus? status,
    DetailsEntity? details,
    String? errorMessage,
    bool clearError = false,
    String? noticeMessage,
    bool clearNotice = false,
    DetailTab? activeDetailTab,
  }) {
    return DetailsState(
      status: status ?? this.status,
      details: details ?? this.details,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
      activeDetailTab: activeDetailTab ?? this.activeDetailTab,
    );
  }

  @override
  List<Object?> get props => [
    status,
    details,
    errorMessage,
    noticeMessage,
    activeDetailTab,
  ];
}
