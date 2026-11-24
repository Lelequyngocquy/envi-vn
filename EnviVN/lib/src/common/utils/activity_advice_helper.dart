import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';

enum ActivitySafetyLevel { safe, caution, avoid }

/// Detailed forecast recommendation for a single outdoor activity window.
class ActivitySlotInfo {
  final String timeRange;
  final String activity;
  final String status;
  final bool isOk;

  const ActivitySlotInfo({
    required this.timeRange,
    required this.activity,
    required this.status,
    required this.isOk,
  });
}

class ActivityAdviceData {
  final ActivitySafetyLevel level;
  final String statusLabel;
  final Color statusColor;
  final String adviceText;
  final List<ActivitySlotInfo> slots;
  final String morningStatus;
  final bool isMorningOk;
  final String eveningStatus;
  final bool isEveningOk;

  const ActivityAdviceData({
    required this.level,
    required this.statusLabel,
    required this.statusColor,
    required this.adviceText,
    required this.slots,
    required this.morningStatus,
    required this.isMorningOk,
    required this.eveningStatus,
    required this.isEveningOk,
  });
}

class _SlotCandidate {
  final DateTime targetTime;
  final String timeRange;
  final String activity;

  const _SlotCandidate({
    required this.targetTime,
    required this.timeRange,
    required this.activity,
  });
}

class ActivityAdviceHelper {
  ActivityAdviceHelper._();

  /// Evaluates current outdoor sport safety and recommends the next two time windows.
  static ActivityAdviceData evaluate({
    required int aqi,
    required double uv,
    required int rainProb,
    DateTime? currentTime,
    List<HourlyDetailsPoint> hourlyWeather = const [],
    List<HourlyAqiPoint> hourlyAqi = const [],
    bool isRaining = false,
    double precipitation = 0.0,
  }) {
    final actuallyRaining = isRaining || precipitation > 0.1;
    final isSafe = !actuallyRaining && aqi <= 100 && uv <= 7 && rainProb <= 40;
    final isAvoid = actuallyRaining || aqi > 150 || uv > 9 || rainProb > 70;
    final level = isSafe
        ? ActivitySafetyLevel.safe
        : (isAvoid ? ActivitySafetyLevel.avoid : ActivitySafetyLevel.caution);
    final (statusLabel, statusColor) = switch (level) {
      ActivitySafetyLevel.safe => ('An toàn', UIColors.aqiGood),
      ActivitySafetyLevel.caution => ('Cần chú ý', UIColors.aqiModerate),
      ActivitySafetyLevel.avoid => ('Không nên', UIColors.aqiUnhealthy),
    };
    final adviceText = _buildAdviceText(
      level: level,
      actuallyRaining: actuallyRaining,
      precipitation: precipitation,
      aqi: aqi,
      uv: uv,
      rainProb: rainProb,
    );
    final slots = resolveTimeSlots(
      currentTime: currentTime ?? DateTime.now(),
      hourlyWeather: hourlyWeather,
      hourlyAqi: hourlyAqi,
      fallbackAqi: aqi,
      fallbackRainProb: rainProb,
    );
    return ActivityAdviceData(
      level: level,
      statusLabel: statusLabel,
      statusColor: statusColor,
      adviceText: adviceText,
      slots: slots,
      morningStatus: slots.isNotEmpty ? slots[0].status : 'Thích hợp',
      isMorningOk: slots.isNotEmpty ? slots[0].isOk : true,
      eveningStatus: slots.length > 1 ? slots[1].status : 'Thích hợp',
      isEveningOk: slots.length > 1 ? slots[1].isOk : true,
    );
  }

  static String _buildAdviceText({
    required ActivitySafetyLevel level,
    required bool actuallyRaining,
    required double precipitation,
    required int aqi,
    required double uv,
    required int rainProb,
  }) {
    if (level == ActivitySafetyLevel.avoid) {
      if (actuallyRaining) {
        return 'Trời đang có mưa (${precipitation > 0 ? '${precipitation.toStringAsFixed(1)} mm' : 'mưa rào'}). Đường trơn trượt nguy hiểm, không nên chạy bộ ngoài trời. Hãy chuẩn bị áo mưa khi đi lại.';
      }
      if (aqi > 150) {
        return 'Chất lượng không khí hiện tại ở mức Xấu (AQI $aqi). Không nên chạy bộ hoặc tập luyện gắng sức ngoài trời để bảo vệ đường hô hấp.';
      }
      if (rainProb > 70) {
        return 'Khu vực hiện có khả năng mưa rất cao ($rainProb%). Đường trơn trượt nguy hiểm, nên chuyển sang chạy máy hoặc tập trong nhà.';
      }
      return 'Chỉ số tia cực tím hiện tại đạt ngưỡng cực đoan (UV ${uv.toStringAsFixed(1)}). Nguy cơ sốc nhiệt và tổn thương da cao, không nên tập ngoài trời.';
    }
    if (level == ActivitySafetyLevel.caution) {
      if (aqi > 100) {
        return 'Không khí lúc này ở mức Kém (AQI $aqi). Nhóm người nhạy cảm nên giảm cự ly hoặc chuyển sang đi bộ nhẹ, đeo khẩu trang PM2.5.';
      }
      if (uv > 7) {
        return 'Tia UV hiện tại ở mức cao (UV ${uv.toStringAsFixed(1)}). Nên chọn cung đường râm mát, đội mũ nón và thoa kem chống nắng đầy đủ.';
      }
      return 'Hiện tại có khả năng xuất hiện mưa rải rác ($rainProb%). Nên chú ý mặt đường ướt và mang theo áo mưa nhẹ dự phòng.';
    }
    return 'Thời tiết và không khí hiện tại rất lý tưởng cho chạy bộ, đạp xe và các hoạt động thể thao ngoài trời.';
  }

  /// Resolves the next two optimal exercise slots based on local time of day.
  static List<ActivitySlotInfo> resolveTimeSlots({
    required DateTime currentTime,
    required List<HourlyDetailsPoint> hourlyWeather,
    required List<HourlyAqiPoint> hourlyAqi,
    int fallbackAqi = 50,
    int fallbackRainProb = 0,
  }) {
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final tomorrow = today.add(const Duration(days: 1));
    final List<_SlotCandidate> candidates;
    if (currentMinutes < 7 * 60 + 30) {
      candidates = [
        _SlotCandidate(
          targetTime: today.add(const Duration(hours: 6)),
          timeRange: '05:30 - 07:30',
          activity: 'Chạy bộ • Sáng nay',
        ),
        _SlotCandidate(
          targetTime: today.add(const Duration(hours: 17)),
          timeRange: '17:00 - 18:30',
          activity: 'Tập luyện • Chiều nay',
        ),
      ];
    } else if (currentMinutes < 18 * 60 + 30) {
      candidates = [
        _SlotCandidate(
          targetTime: today.add(const Duration(hours: 17)),
          timeRange: '17:00 - 18:30',
          activity: 'Tập luyện • Chiều nay',
        ),
        _SlotCandidate(
          targetTime: tomorrow.add(const Duration(hours: 6)),
          timeRange: '05:30 - 07:30',
          activity: 'Chạy bộ • Sáng mai',
        ),
      ];
    } else if (currentMinutes < 21 * 60) {
      candidates = [
        _SlotCandidate(
          targetTime: today.add(const Duration(hours: 20)),
          timeRange: '19:00 - 21:00',
          activity: 'Đi bộ • Tối nay',
        ),
        _SlotCandidate(
          targetTime: tomorrow.add(const Duration(hours: 6)),
          timeRange: '05:30 - 07:30',
          activity: 'Chạy bộ • Sáng mai',
        ),
      ];
    } else {
      candidates = [
        _SlotCandidate(
          targetTime: tomorrow.add(const Duration(hours: 6)),
          timeRange: '05:30 - 07:30',
          activity: 'Chạy bộ • Sáng mai',
        ),
        _SlotCandidate(
          targetTime: tomorrow.add(const Duration(hours: 17)),
          timeRange: '17:00 - 18:30',
          activity: 'Tập luyện • Chiều mai',
        ),
      ];
    }
    return candidates.map((candidate) {
      final weatherPoint = _findClosestByTime(
        hourlyWeather,
        candidate.targetTime,
        (p) => p.time,
      );
      final aqiPoint = _findClosestByTime(
        hourlyAqi,
        candidate.targetTime,
        (p) => p.time,
      );
      final slotAqi = (aqiPoint != null && aqiPoint.aqi > 0)
          ? aqiPoint.aqi
          : fallbackAqi;
      final slotRainProb =
          weatherPoint?.precipitationProbability ?? fallbackRainProb;
      final slotTemp = weatherPoint?.temperature;
      final isAqiBad = slotAqi > 150;
      final isAqiCaution = slotAqi > 100 && slotAqi <= 150;
      final isRainHeavy = slotRainProb >= 65;
      final isRainCaution = slotRainProb >= 40 && slotRainProb < 65;
      final isTooHot = slotTemp != null && slotTemp >= 38.0;
      final isOk = !isAqiBad && !isRainHeavy && !isAqiCaution && !isTooHot;
      final status = isAqiBad
          ? 'Không khí xấu (AQI $slotAqi)'
          : isRainHeavy
          ? 'Nguy cơ mưa $slotRainProb%'
          : isAqiCaution
          ? 'Nên đeo khẩu trang'
          : isTooHot
          ? 'Nắng nóng ${slotTemp.round()}°C'
          : isRainCaution
          ? 'Khả năng mưa $slotRainProb%'
          : (slotAqi <= 50 && slotRainProb <= 20
                ? 'Rất lý tưởng'
                : 'Thích hợp');
      return ActivitySlotInfo(
        timeRange: candidate.timeRange,
        activity: candidate.activity,
        status: status,
        isOk: isOk,
      );
    }).toList();
  }

  static T? _findClosestByTime<T>(
    List<T> list,
    DateTime target,
    DateTime Function(T) getTime,
  ) {
    if (list.isEmpty) return null;
    T closest = list.first;
    int minDiff = getTime(closest).difference(target).inMinutes.abs();
    for (final item in list) {
      final t = getTime(item);
      if (t.year == target.year &&
          t.month == target.month &&
          t.day == target.day &&
          t.hour == target.hour) {
        return item;
      }
      final diff = t.difference(target).inMinutes.abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = item;
      }
    }
    return closest;
  }
}
