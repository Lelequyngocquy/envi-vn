import '../../../../core/domain/utils/wmo_weather_rules.dart';
import 'advisor_decision.dart';

enum QuickPromptType {
  running(label: 'Chạy bộ ngoài trời'),
  ventilation(label: 'Mở cửa thông gió'),
  childrenOutdoor(label: 'Trẻ em & Người già'),
  commute(label: 'Đi lại & Đi làm');

  final String label;

  const QuickPromptType({required this.label});

  AdvisorDecision evaluate({
    required int aqi,
    required double pm25,
    required double temperature,
    double? uvIndex,
    bool hasRespiratoryCondition = false,
    bool isRaining = false,
    int rainProbability = 0,
    double precipitation = 0.0,
    int? weatherCode,
  }) {
    final isRainCode = WmoWeatherRules.isRainCode(weatherCode);
    final isThunder = WmoWeatherRules.isThunderCode(weatherCode);
    final actuallyRaining = isRaining || precipitation > 0.1 || isRainCode;
    final isHighRainChance = rainProbability >= 60;
    switch (this) {
      case QuickPromptType.running:
        if (actuallyRaining || isThunder) return AdvisorDecision.runningRainWarning;
        if (hasRespiratoryCondition && (aqi > 75 || pm25 > 25.0)) return AdvisorDecision.runningSensitiveWarning;
        if (aqi > 150 || pm25 > 55.0) return AdvisorDecision.runningSevereAirDanger;
        if (temperature > 34.0 || (uvIndex != null && uvIndex >= 7.5)) return AdvisorDecision.runningHeatOrUvRisk;
        if (isHighRainChance) return AdvisorDecision.runningRainWarning;
        if (aqi > 50 || pm25 > 15.0) return AdvisorDecision.runningCautious;
        return AdvisorDecision.runningIdeal;
      case QuickPromptType.ventilation:
        if (aqi > 100 || pm25 > 35.0) return AdvisorDecision.ventilationKeepClosed;
        if (aqi > 50 || pm25 > 15.0) return AdvisorDecision.ventilationBriefOnly;
        return AdvisorDecision.ventilationOptimal;
      case QuickPromptType.childrenOutdoor:
        if (actuallyRaining || isThunder) return AdvisorDecision.childrenRainWarning;
        if (aqi > 150 || pm25 > 55.0 || (hasRespiratoryCondition && aqi > 75)) return AdvisorDecision.childrenStayIndoorDanger;
        if (aqi > 50 || pm25 > 15.0 || (uvIndex != null && uvIndex >= 6.0) || isHighRainChance) return AdvisorDecision.childrenNeedCaution;
        return AdvisorDecision.childrenSafeToGo;
      case QuickPromptType.commute:
        if (actuallyRaining || isHighRainChance) {
          if (aqi > 100 || pm25 > 35.0) return AdvisorDecision.commuteRainAndPollutionWarning;
          return AdvisorDecision.commuteRainWarning;
        }
        if (aqi > 100 || pm25 > 35.0) return AdvisorDecision.commuteRequireN95Protective;
        if (aqi > 50 || pm25 > 15.0) return AdvisorDecision.commuteRequireRegularMask;
        return AdvisorDecision.commuteSafeConditions;
    }
  }
}
