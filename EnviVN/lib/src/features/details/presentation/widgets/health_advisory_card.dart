import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/common/utils/aqi_helper.dart';
import 'package:envivn/src/core/presentation/widgets/widgets.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

class HealthAdvisoryCard extends StatelessWidget {
  final int aqi;

  const HealthAdvisoryCard({super.key, this.aqi = 0});

  @override
  Widget build(BuildContext context) {
    final hasData = aqi > 0;
    final info = hasData ? AQIHelper.getAQIInfo(aqi) : null;
    final accentColor = info?.color ?? UIColors.textMuted;
    final iconData = !hasData
        ? Icons.info_outline_rounded
        : (aqi > 100 ? Icons.warning_amber_rounded : Icons.verified_user_outlined);
    final advisoryText = hasData
        ? '${info!.healthAdvice} ${info.outdoorAdvice}'
        : 'Chưa có dữ liệu chất lượng không khí để đưa ra khuyến cáo sức khỏe.';
    return AppGlass(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.18), shape: BoxShape.circle),
            child: AppIcon(iconData, color: accentColor, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bold(
                  hasData ? 'Khuyến cáo sức khỏe (AQI $aqi • ${info!.label})' : 'Khuyến cáo sức khỏe',
                  size: 14,
                  color: UIColors.textPrimary,
                ),
                const Gap(6),
                AppText.regular(advisoryText, size: 12, color: UIColors.textSecondary, height: 1.45),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
