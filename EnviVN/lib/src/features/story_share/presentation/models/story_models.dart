import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';

enum StoryRatio {
  story(9 / 16, '9:16', 'Story', Icons.crop_portrait_rounded),
  square(1.0, '1:1', 'Vuông', Icons.crop_square_rounded),
  portrait(4 / 5, '4:5', 'Dọc', Icons.crop_5_4_rounded);

  final double ratioValue;
  final String label;
  final String description;
  final IconData icon;

  const StoryRatio(this.ratioValue, this.label, this.description, this.icon);
}

enum StoryCardType {
  airQuality,
  weather,
  floodRisk,
  advisorHealth,
  outdoorActivity,
  windAtmosphere,
}

class StoryCardMeta {
  final StoryCardType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const StoryCardMeta({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  static const List<StoryCardMeta> all = [
    StoryCardMeta(
      type: StoryCardType.airQuality,
      title: 'Chất lượng không khí',
      subtitle: 'AQI US • Nồng độ bụi PM2.5 & PM10',
      icon: Icons.air_rounded,
      iconColor: UIColors.primary,
    ),
    StoryCardMeta(
      type: StoryCardType.weather,
      title: 'Thời tiết hiện tại',
      subtitle: 'Nhiệt độ • Cảm giác thực • Chỉ số UV',
      icon: Icons.wb_sunny_rounded,
      iconColor: UIColors.warning,
    ),
    StoryCardMeta(
      type: StoryCardType.floodRisk,
      title: 'Nguy cơ ngập & Mưa',
      subtitle: 'Khả năng mưa • Cảnh báo dông ngập',
      icon: Icons.flood_rounded,
      iconColor: UIColors.secondary,
    ),
    StoryCardMeta(
      type: StoryCardType.advisorHealth,
      title: 'Cố vấn sức khỏe y tế',
      subtitle: 'Khẩu trang • Cảnh báo nhóm nhạy cảm',
      icon: Icons.health_and_safety_rounded,
      iconColor: UIColors.primaryDark,
    ),
    StoryCardMeta(
      type: StoryCardType.outdoorActivity,
      title: 'Cố vấn thể thao ngoài trời',
      subtitle: 'Chạy bộ • Đạp xe • Giờ lý tưởng',
      icon: Icons.directions_run_rounded,
      iconColor: UIColors.pinPurple,
    ),
    StoryCardMeta(
      type: StoryCardType.windAtmosphere,
      title: 'Gió & Khí quyển',
      subtitle: 'Tốc độ gió • Độ ẩm • Áp suất khí quyển',
      icon: Icons.speed_rounded,
      iconColor: UIColors.gpsBlue,
    ),
  ];
}
