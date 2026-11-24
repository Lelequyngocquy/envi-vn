import 'dart:async';

import 'package:flutter/material.dart';

import '../../common/constants/colors.dart';
import '../../core/presentation/widgets/app_icon.dart';
import 'glass.dart';

class AppCircleButton extends StatefulWidget {
  const AppCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconSize = 22,
    this.iconColor = UIColors.primary,
    this.tooltip,
    this.borderRadius = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    this.isFixed = true,
    this.enable = true,
    this.isLoading,
    this.showDot = false,
    this.dotColor = UIColors.error,
  });

  final IconData icon;
  final FutureOr<dynamic> Function()? onTap;
  final double iconSize;
  final Color iconColor;
  final String? tooltip;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isFixed;
  final bool enable;
  final bool? isLoading;
  final bool? showDot;
  final Color dotColor;

  @override
  State<AppCircleButton> createState() => _AppCircleButtonState();
}

class _AppCircleButtonState extends State<AppCircleButton> {
  bool _internalLoading = false;

  bool get _isLoading => widget.isLoading ?? _internalLoading;

  Future<void> _handleTap() async {
    if (_isLoading || !widget.enable || widget.onTap == null) return;
    setState(() => _internalLoading = true);
    try {
      final result = widget.onTap!();
      if (result is Future) {
        await result;
      }
    } finally {
      if (mounted) {
        setState(() => _internalLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enable
        ? widget.iconColor
        : UIColors.textMuted;
    final button = GestureDetector(
      onTap: (widget.enable && !_isLoading && widget.onTap != null)
          ? _handleTap
          : null,
      behavior: HitTestBehavior.opaque,
      child: AppGlass(
        isFixed: widget.isFixed,
        borderRadius: widget.borderRadius,
        padding: widget.padding,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? SizedBox(
                  key: const ValueKey('circle_loading'),
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
                  ),
                )
              : SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AppIcon(
                        widget.icon,
                        key: const ValueKey('circle_icon'),
                        color: effectiveColor,
                        size: widget.iconSize,
                      ),
                      if (widget.showDot == true)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: (widget.iconSize * 0.32).clamp(6.0, 9.0),
                            height: (widget.iconSize * 0.32).clamp(6.0, 9.0),
                            decoration: BoxDecoration(
                              color: widget.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String? tooltip;
  final bool isFixed;

  const AppBackButton({
    super.key,
    this.onTap,
    this.borderRadius = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.iconSize = 16,
    this.iconColor,
    this.tooltip = 'Quay lại',
    this.isFixed = true,
  });

  void _handleBack(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCircleButton(
      icon: icon,
      iconSize: iconSize,
      iconColor: iconColor ?? UIColors.textPrimary,
      borderRadius: borderRadius,
      padding: padding,
      tooltip: tooltip,
      isFixed: isFixed,
      onTap: () => _handleBack(context),
    );
  }
}
