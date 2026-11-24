import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/utils/heat_index_helper.dart';
import '../../../../../core/presentation/widgets/app_icon.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../domain/entities/station_entity.dart';
import '../../extensions/map_ui_extensions.dart';
import 'station_preview_shared.dart';

class StationThermalPreview extends StatelessWidget {
  final StationEntity station;

  const StationThermalPreview({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    if (station.isThermalHotspot) {
      return _buildHotspotContent();
    }
    return _buildHeatIndexContent();
  }

  Widget _buildHotspotContent() {
    final isActive = station.isActiveFire;
    final statusColor = isActive ? UIColors.markerRedDark : UIColors.aqiGood;
    final statusIcon = isActive
        ? Icons.local_fire_department_rounded
        : Icons.check_circle_outline_rounded;
    final tempStr = isActive
        ? '${(station.fireBrightnessCelsius ?? 55).toStringAsFixed(0)}°C'
        : '${(station.temperature ?? 28).toStringAsFixed(0)}°C';
    final statusTitle = isActive
        ? 'CẢNH BÁO: TÍN HIỆU PHÁT XẠ NHIỆT'
        : 'Hiện tại: Bình thường - Không ghi nhận điểm nhiệt';
    final statusSubtitle = isActive
        ? '${station.fireType ?? "Điểm nhiệt bề mặt"} • Độ tin cậy vệ tinh: ${(station.fireConfidence ?? 90).toStringAsFixed(0)}%'
        : 'Nhiệt độ môi trường: ${(station.temperature ?? 28).toStringAsFixed(0)}°C • Không có tín hiệu nhiệt bất thường';
    final boxColor = isActive ? UIColors.markerRedDark : UIColors.warning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PreviewBadgeBox(
              color: statusColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(statusIcon, size: 20, color: statusColor),
                  const Gap(2),
                  AppText.extraBold(
                    tempStr,
                    size: 13,
                    color: statusColor,
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
                    statusTitle,
                    size: 12.5,
                    color: statusColor,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(3),
                  AppText.regular(
                    statusSubtitle,
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
        const Gap(6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: boxColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: boxColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    isActive
                        ? Icons.local_fire_department_rounded
                        : Icons.whatshot_outlined,
                    size: 13,
                    color: boxColor,
                  ),
                  const Gap(5),
                  Expanded(
                    child: AppText.bold(
                      isActive
                          ? 'TÍN HIỆU NHIỆT PHÁT HIỆN QUA VỆ TINH NASA'
                          : 'VÙNG CÓ BIẾN ĐỘNG NHIỆT THEO CHU KỲ',
                      size: 10,
                      color: boxColor,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isActive && station.fireDetectedTime != null) ...[
                const Gap(3),
                AppText.regular(
                  '⏱️ ${station.fireDetectedTime!}',
                  size: 9.5,
                  color: UIColors.textPrimary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!isActive && station.fireProneSeason != null) ...[
                const Gap(3),
                PreviewLabeledRow(
                  label: '⏱️ Thời điểm: ',
                  value: station.fireProneSeason!,
                ),
              ],
              if (station.spotDescription != null) ...[
                const Gap(2),
                PreviewLabeledRow(
                  label: '📍 Ghi nhận: ',
                  value: station.spotDescription!,
                ),
              ],
            ],
          ),
        ),
        const Gap(6),
        PreviewTipBanner(
          icon: isActive ? Icons.warning_rounded : Icons.info_outline_rounded,
          color: boxColor,
          text: isActive
              ? 'Ghi nhận bức xạ nhiệt tăng cao! Người dân lân cận nên chú ý theo dõi chất lượng không khí và che chắn khi ra ngoài.'
              : 'Hiện tại chưa ghi nhận điểm nhiệt bất thường. Khu vực này có thể xuất hiện biến động nhiệt theo mùa khô hoặc chu kỳ thời tiết.',
        ),
      ],
    );
  }

  Widget _buildHeatIndexContent() {
    final heatIndex = station.calculatedHeatIndex;
    final risk = station.heatRiskLevel;
    final uv = station.uvIndex ?? 6.0;
    final sunburnAdvice = HeatIndexHelper.getSunburnTimeAdvice(uv);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PreviewBadgeBox(
              color: risk.color,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(risk.icon, size: 20, color: risk.color),
                  const Gap(2),
                  AppText.extraBold(
                    '${heatIndex.toStringAsFixed(0)}°C',
                    size: 14,
                    color: risk.color,
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
                  AppText.rich(
                    TextSpan(
                      text: risk.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: risk.color,
                      ),
                      children: [
                        TextSpan(
                          text:
                              ' • Nhiệt thực ${(station.temperature ?? 28).toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: UIColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      AppText.regular(
                        '☀️ UV: ${uv.toStringAsFixed(1)}',
                        size: 10.5,
                        color: UIColors.textSecondary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText.regular(
                        '⏱️ Phơi nắng an toàn: $sunburnAdvice',
                        size: 10.5,
                        color: UIColors.textSecondary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(7),
        PreviewTipBanner(
          icon: Icons.wb_sunny_rounded,
          color: risk.color,
          text: risk.description,
        ),
      ],
    );
  }
}
