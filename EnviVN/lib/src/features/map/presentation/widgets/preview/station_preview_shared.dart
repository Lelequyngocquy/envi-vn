import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../core/presentation/widgets/app_icon.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../domain/entities/map_layer_type.dart';

class PreviewTipBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const PreviewTipBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: UIColors.surfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcon(icon, color: color, size: 13),
          ),
          const Gap(6),
          Expanded(
            child: AppText.regular(
              text,
              size: 10,
              color: UIColors.textPrimary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewBadgeBox extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PreviewBadgeBox({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

class PreviewLabeledRow extends StatelessWidget {
  final String label;
  final String value;

  const PreviewLabeledRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.regular(
          label,
          size: 9.5,
          color: UIColors.textSecondary,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        Expanded(
          child: AppText.regular(
            value,
            size: 9.5,
            color: UIColors.textPrimary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class PreviewLoadingContent extends StatelessWidget {
  final MapLayerType activeLayer;

  const PreviewLoadingContent({super.key, required this.activeLayer});

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, subtitle) = switch (activeLayer) {
      MapLayerType.weather => (
        Icons.cloud_sync_rounded,
        UIColors.secondary,
        'Đang đồng bộ dữ liệu thời tiết...',
        'Nhiệt độ, độ ẩm, sức gió và lượng mưa theo thời gian thực',
      ),
      MapLayerType.airQuality => (
        Icons.air_rounded,
        UIColors.aqiGood,
        'Đang đo lường chất lượng không khí...',
        'Phân tích chỉ số AQI và nồng độ bụi mịn PM2.5, PM10',
      ),
      MapLayerType.thermal => (
        Icons.thermostat_rounded,
        UIColors.aqiUnhealthySensitive,
        'Đang tính toán nguy cơ sốc nhiệt & tia cực tím...',
        'Chỉ số nhiệt Heat Index và bức xạ UV từ vệ tinh',
      ),
      MapLayerType.flood => (
        Icons.water_drop_rounded,
        UIColors.gpsBlue,
        'Đang phân tích nguy cơ ngập úng...',
        'Lưu lượng mưa tức thời và lưu thông dòng chảy',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                AppIcon(icon, size: 18, color: color),
              ],
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bold(
                  title,
                  size: 12.5,
                  color: UIColors.textPrimary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),
                AppText.regular(
                  subtitle,
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
    );
  }
}
