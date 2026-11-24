import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';

/// Action button bar used inside AppDialog for single or dual-action layouts.
class AppDialogActions extends StatelessWidget {
  final bool hasLeft;
  final bool hasRight;
  final String leftTitle;
  final VoidCallback leftFunc;
  final String? rightTitle;
  final VoidCallback? rightFunc;
  final Color? rightColor;
  final bool isDestructive;

  const AppDialogActions({
    super.key,
    required this.hasLeft,
    required this.hasRight,
    required this.leftTitle,
    required this.leftFunc,
    this.rightTitle,
    this.rightFunc,
    this.rightColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDestructive
        ? UIColors.error
        : (rightColor ?? UIColors.primary);
    final primaryTextColor = isDestructive ? UIColors.white : UIColors.bg;
    if (hasLeft && hasRight) {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              title: leftTitle,
              onTap: leftFunc,
              bgColor: UIColors.white.withValues(alpha: 0.08),
              borderColor: UIColors.white.withValues(alpha: 0.14),
              textColor: UIColors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(10),
          Expanded(
            child: _buildActionButton(
              title: rightTitle!,
              onTap: rightFunc,
              bgColor: primaryColor,
              shadowColor: primaryColor.withValues(alpha: 0.35),
              textColor: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    final isLeftOnly = hasLeft && !hasRight;
    return SizedBox(
      width: double.infinity,
      child: _buildActionButton(
        title: isLeftOnly ? leftTitle : rightTitle!,
        onTap: isLeftOnly ? leftFunc : rightFunc,
        bgColor: isLeftOnly
            ? UIColors.white.withValues(alpha: 0.1)
            : primaryColor,
        borderColor: isLeftOnly ? UIColors.white.withValues(alpha: 0.14) : null,
        shadowColor: isLeftOnly ? null : primaryColor.withValues(alpha: 0.35),
        textColor: isLeftOnly ? UIColors.white : primaryTextColor,
        fontWeight: isLeftOnly ? FontWeight.w600 : FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required VoidCallback? onTap,
    required Color bgColor,
    Color? borderColor,
    Color? shadowColor,
    required Color textColor,
    required FontWeight fontWeight,
  }) {
    return Material(
      color: UIColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 0.8)
                : null,
            boxShadow: shadowColor != null
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AppText(
            title,
            size: 13.5,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
