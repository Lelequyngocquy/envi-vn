import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';
import 'package:envivn/src/shared/widgets/app_button.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

import 'radar_illustration_widget.dart';

class FutureWorkHighlight {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;

  const FutureWorkHighlight({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
  });
}

class FutureWorkWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final IconData centerIcon;
  final List<FutureWorkHighlight>? highlights;
  final VoidCallback? onBack;
  final String backButtonText;
  final double bottomPadding;

  const FutureWorkWidget({
    super.key,
    this.title = 'Tính năng đang phát triển',
    this.subtitle =
        'Đội ngũ EnviVN đang tích cực hoàn thiện tính năng này để mang lại dữ liệu môi trường và trải nghiệm tối ưu nhất cho bạn.',
    this.badgeText = 'SẮP RA MẮT • COMING SOON',
    this.centerIcon = Icons.auto_awesome_rounded,
    this.highlights,
    this.onBack,
    this.backButtonText = 'Quay lại',
    this.bottomPadding = 80,
  });

  static Future<T?> push<T>(
    BuildContext context, {
    String title = 'Tính năng đang phát triển',
    String subtitle =
        'Đội ngũ EnviVN đang tích cực hoàn thiện tính năng này để mang lại dữ liệu môi trường và trải nghiệm tối ưu nhất cho bạn.',
    String? badgeText,
    IconData centerIcon = Icons.auto_awesome_rounded,
    List<FutureWorkHighlight>? highlights,
    VoidCallback? onBack,
    String backButtonText = 'Quay lại',
    double bottomPadding = 80,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => FutureWorkWidget(
          title: title,
          subtitle: subtitle,
          badgeText: badgeText,
          centerIcon: centerIcon,
          highlights: highlights,
          onBack: onBack,
          backButtonText: backButtonText,
          bottomPadding: bottomPadding,
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Gap(128),
                        RadarIllustrationWidget(centerIcon: centerIcon),
                        const Gap(32),
                        if (badgeText != null && badgeText!.isNotEmpty) ...[
                          _buildStatusBadge(),
                          const Gap(16),
                        ],
                        AppText.bold(
                          title,
                          textAlign: TextAlign.center,
                          size: 24,
                          color: UIColors.textPrimary,
                          height: 1.3,
                        ),
                        const Gap(14),
                        AppText.regular(
                          subtitle,
                          textAlign: TextAlign.center,
                          size: 14,
                          color: UIColors.textSecondary,
                          height: 1.5,
                        ),
                        if (highlights != null && highlights!.isNotEmpty) ...[
                          const Gap(20),
                          _buildHighlightsCard(),
                        ],
                        const Spacer(),
                        AppButton(
                          onTap: () => _handleBack(context),
                          title: backButtonText,
                          icon: Icons.arrow_back_rounded,
                        ),
                        const Gap(24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: UIColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: UIColors.primary.withValues(alpha: 0.32),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: UIColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: UIColors.primary.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const Gap(8),
          AppText.bold(
            badgeText!,
            size: 11,
            letterSpacing: 0.8,
            color: UIColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard() {
    return AppGlass(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(highlights!.length, (index) {
          final item = highlights![index];
          final iconColor = item.iconColor ?? UIColors.secondary;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == highlights!.length - 1 ? 0 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: AppIcon(item.icon, size: 18, color: iconColor),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.semiBold(
                        item.title,
                        size: 13,
                        color: UIColors.textPrimary,
                      ),
                      const Gap(2),
                      AppText.regular(
                        item.description,
                        size: 11,
                        color: UIColors.textSecondary,
                        height: 1.4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
