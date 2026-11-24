import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../core/presentation/widgets/app_icon.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../domain/entities/station_entity.dart';
import 'station_preview_shared.dart';

class StationFloodPreview extends StatelessWidget {
  final StationEntity station;

  const StationFloodPreview({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final rain = station.precipitation ?? 0.0;
    final isBlackspot = station.isFloodBlackspot;
    final isHighRain = rain >= 20.0;
    final hasRain = rain > 0.0;
    final Color liveColor;
    final IconData liveIcon;
    final String liveStatus;
    final String liveDetail;
    if (isHighRain) {
      liveColor = UIColors.markerRed;
      liveIcon = Icons.waves_rounded;
      liveStatus = 'CẢNH BÁO: NGUY CƠ NGẬP';
      liveDetail = isBlackspot
          ? 'Mưa lớn ${rain.toStringAsFixed(1)}mm/h • Dễ ngập ~${station.historicalDepthCm ?? 35}cm'
          : 'Mưa lớn ${rain.toStringAsFixed(1)}mm/h • Tiêu thoát chậm';
    } else if (hasRain) {
      liveColor = UIColors.secondary;
      liveIcon = Icons.water_drop_outlined;
      liveStatus = 'Mưa nhẹ - Lưu thông bình thường';
      liveDetail =
          'Lượng mưa: ${rain.toStringAsFixed(1)}mm/h • Độ ẩm: ${station.humidity ?? 80}%';
    } else {
      liveColor = UIColors.aqiGood;
      liveIcon = Icons.check_circle_outline_rounded;
      liveStatus = 'Hiện tại: Khô ráo - Thông thoáng';
      liveDetail =
          'Không có mưa (0.0mm) • Độ ẩm: ${station.humidity ?? 65}% • Lưu thông tốt';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PreviewBadgeBox(
              color: liveColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(liveIcon, size: 20, color: liveColor),
                  const Gap(2),
                  AppText.extraBold(
                    '${rain.toStringAsFixed(1)}mm',
                    size: 12.5,
                    color: liveColor,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bold(
                    liveStatus,
                    size: 12.5,
                    color: liveColor,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(3),
                  AppText.regular(
                    liveDetail,
                    size: 10.5,
                    color: UIColors.textSecondary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isBlackspot) ...[
          const Gap(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: UIColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: UIColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: UIColors.warning,
                    ),
                    const Gap(5),
                    Expanded(
                      child: AppText.rich(
                        TextSpan(
                          text: 'ĐIỂM ĐEN THƯỜNG NGẬP KHI MƯA LỚN',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: UIColors.warning,
                          ),
                          children: station.historicalDepthCm != null
                              ? [
                                  TextSpan(
                                    text:
                                        ' • Ngập sâu ~${station.historicalDepthCm}cm',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: UIColors.warning,
                                    ),
                                  ),
                                ]
                              : null,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (station.floodProneTime != null) ...[
                  const Gap(3),
                  PreviewLabeledRow(
                    label: '⏱️ Thời điểm: ',
                    value: station.floodProneTime!,
                  ),
                ],
                if (station.floodTriggerCondition != null) ...[
                  const Gap(2),
                  PreviewLabeledRow(
                    label: '⚠️ Điều kiện: ',
                    value: station.floodTriggerCondition!,
                  ),
                ],
              ],
            ),
          ),
        ],
        const Gap(6),
        PreviewTipBanner(
          icon: isHighRain
              ? Icons.warning_rounded
              : (isBlackspot
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded),
          color: isHighRain
              ? UIColors.markerRed
              : (isBlackspot ? UIColors.warning : liveColor),
          text: isHighRain
              ? 'Lượng mưa vượt ngưỡng an toàn! Hãy chủ động tránh hầm chui & vùng trũng.'
              : (isBlackspot
                    ? 'Hiện tại không ngập. Lưu ý chủ động phương án di chuyển khi có mưa dông hoặc triều cường.'
                    : 'Lưu lượng tiêu thoát nước bình thường, không ghi nhận tình trạng ứ đọng ngập úng.'),
        ),
      ],
    );
  }
}
