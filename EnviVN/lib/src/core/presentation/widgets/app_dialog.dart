import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';
import 'package:envivn/src/core/presentation/widgets/app_text.dart';
import 'package:envivn/src/shared/widgets/glass.dart';

import 'app_dialog_actions.dart';

/// Shared dark-glass modal dialog supporting custom headers, content, and actions.
class AppDialog extends StatelessWidget {
  final Widget? header;
  final IconData? icon;
  final Color? iconColor;
  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? childrenWidget;
  final String? leftButtonTitle;
  final VoidCallback? leftButtonFunc;
  final bool showLeftButton;
  final String? rightButtonTitle;
  final VoidCallback? rightButtonFunc;
  final Color? rightButtonColor;
  final bool isDestructive;
  final bool showButtons;
  final bool barrierDismissible;
  final VoidCallback? onDismiss;
  final bool canPop;
  final Color? glowColor;
  final double maxWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color? barrierColor;

  const AppDialog({
    super.key,
    this.header,
    this.icon,
    this.iconColor,
    this.title,
    this.titleWidget,
    this.content,
    this.childrenWidget,
    this.leftButtonTitle,
    this.leftButtonFunc,
    this.showLeftButton = true,
    this.rightButtonTitle,
    this.rightButtonFunc,
    this.rightButtonColor,
    this.isDestructive = false,
    this.showButtons = true,
    this.barrierDismissible = true,
    this.onDismiss,
    this.canPop = true,
    this.glowColor,
    this.maxWidth = 310.0,
    this.borderRadius = 28.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
    this.blurSigma = 10.0,
    this.barrierColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    Widget? header,
    IconData? icon,
    Color? iconColor,
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? childrenWidget,
    String? leftButtonTitle,
    VoidCallback? leftButtonFunc,
    bool showLeftButton = true,
    String? rightButtonTitle,
    VoidCallback? rightButtonFunc,
    Color? rightButtonColor,
    bool isDestructive = false,
    bool showButtons = true,
    bool barrierDismissible = true,
    VoidCallback? onDismiss,
    bool canPop = true,
    Color? glowColor,
    double maxWidth = 310.0,
    double borderRadius = 28.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 26,
    ),
    double blurSigma = 10.0,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'AppDialog',
      barrierColor: UIColors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AppDialog(
          header: header,
          icon: icon,
          iconColor: iconColor,
          title: title,
          titleWidget: titleWidget,
          content: content,
          childrenWidget: childrenWidget,
          leftButtonTitle: leftButtonTitle,
          leftButtonFunc: leftButtonFunc,
          showLeftButton: showLeftButton,
          rightButtonTitle: rightButtonTitle,
          rightButtonFunc: rightButtonFunc,
          rightButtonColor: rightButtonColor,
          isDestructive: isDestructive,
          showButtons: showButtons,
          barrierDismissible: barrierDismissible,
          onDismiss: onDismiss,
          canPop: canPop,
          glowColor: glowColor,
          maxWidth: maxWidth,
          borderRadius: borderRadius,
          padding: padding,
          blurSigma: blurSigma,
          barrierColor: barrierColor,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRightButton =
        rightButtonTitle != null && rightButtonTitle!.isNotEmpty;
    final hasLeftButton = showButtons && showLeftButton;
    final effectiveLeftTitle =
        leftButtonTitle ?? (hasRightButton ? 'Hủy' : 'Đóng');
    final effectiveLeftFunc =
        leftButtonFunc ?? () => Navigator.of(context).maybePop();
    final effectiveIconColor = iconColor ?? UIColors.primary;
    return PopScope(
      canPop: canPop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              color: barrierColor ?? UIColors.black.withValues(alpha: 0.62),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: barrierDismissible
                ? (onDismiss ?? () => Navigator.of(context).maybePop())
                : null,
            child: const SizedBox.expand(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color:
                          glowColor ?? UIColors.primary.withValues(alpha: 0.24),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                // Avoid double BackdropFilter since the full-screen barrier already blurs the backdrop.
                child: AppGlass(
                  enableBlur: false,
                  borderRadius: borderRadius,
                  padding: padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (header != null) ...[
                        header!,
                        const Gap(20),
                      ] else if (icon != null) ...[
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: effectiveIconColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: effectiveIconColor.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: AppIcon(
                            icon!,
                            size: 28,
                            color: effectiveIconColor,
                          ),
                        ),
                        const Gap(18),
                      ],
                      if (titleWidget != null) ...[
                        titleWidget!,
                        const Gap(8),
                      ] else if (title != null) ...[
                        AppText.bold(
                          title!,
                          textAlign: TextAlign.center,
                          size: 16.5,
                          letterSpacing: 0.2,
                        ),
                        const Gap(8),
                      ],
                      ?childrenWidget,
                      if (content != null) ...[
                        if (childrenWidget != null) const Gap(8),
                        AppText.regular(
                          content!,
                          textAlign: TextAlign.center,
                          size: 12.5,
                          color: UIColors.textSecondary,
                          height: 1.45,
                        ),
                      ],
                      if (showButtons && (hasLeftButton || hasRightButton)) ...[
                        const Gap(22),
                        AppDialogActions(
                          hasLeft: hasLeftButton,
                          hasRight: hasRightButton,
                          leftTitle: effectiveLeftTitle,
                          leftFunc: effectiveLeftFunc,
                          rightTitle: rightButtonTitle,
                          rightFunc: rightButtonFunc,
                          rightColor: rightButtonColor,
                          isDestructive: isDestructive,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
