import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/presentation/widgets/future_work_widget.dart';
import '../../../../shared/router/router_key_manager.dart';
import '../../domain/entities/explore_utility.dart';

extension ExploreUtilityUiX on ExploreUtility {
  IconData get icon {
    switch (this) {
      case ExploreUtility.storyShare:
        return Icons.ios_share_rounded;
      case ExploreUtility.desktopWidget:
        return Icons.widgets_rounded;
      case ExploreUtility.morningReport:
        return Icons.notifications_active_rounded;
      case ExploreUtility.environmentalReport:
        return Icons.picture_as_pdf_rounded;
      case ExploreUtility.healthProfile:
        return Icons.health_and_safety_rounded;
      case ExploreUtility.nasaRadar:
        return Icons.radar_rounded;
      case ExploreUtility.monitoringHistory:
        return Icons.history_rounded;
      case ExploreUtility.multiPointCompare:
        return Icons.compare_arrows_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case ExploreUtility.storyShare:
        return UIColors.primary;
      case ExploreUtility.desktopWidget:
      case ExploreUtility.healthProfile:
        return UIColors.secondary;
      case ExploreUtility.morningReport:
      case ExploreUtility.multiPointCompare:
        return UIColors.warning;
      case ExploreUtility.environmentalReport:
        return UIColors.error;
      case ExploreUtility.nasaRadar:
        return UIColors.pinPurple;
      case ExploreUtility.monitoringHistory:
        return UIColors.primaryDark;
    }
  }

  Color get badgeColor => isAvailable ? UIColors.primary : UIColors.textMuted;

  void handleTap(BuildContext context) {
    if (this == ExploreUtility.storyShare) {
      Navigator.pushNamed(context, RouterPath.storyShare);
      return;
    }
    FutureWorkWidget.push(
      context,
      title: futureTitle ?? title,
      subtitle: futureSubtitle ?? subtitle,
      badgeText: 'SẮP RA MẮT • COMING SOON',
      centerIcon: icon,
      bottomPadding: 0,
    );
  }
}
