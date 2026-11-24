import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../common/constants/colors.dart';
import '../../core/presentation/widgets/app_icon.dart';
import '../../core/presentation/widgets/app_text.dart';
import 'glass.dart';

class AppTwoButtons extends StatefulWidget {
  const AppTwoButtons({
    super.key,
    required this.primaryTitle,
    required this.primaryOnTap,
    this.primaryIcon,
    this.primaryEnable = true,
    this.isPrimaryLoading,
    this.secondaryTitle,
    this.secondaryOnTap,
    this.secondaryIcon,
    this.secondaryEnable = true,
    this.isSecondaryLoading,
    this.isLoading,
  });

  final String primaryTitle;
  final FutureOr<dynamic> Function()? primaryOnTap;
  final IconData? primaryIcon;
  final bool primaryEnable;
  final bool? isPrimaryLoading;
  final String? secondaryTitle;
  final FutureOr<dynamic> Function()? secondaryOnTap;
  final IconData? secondaryIcon;
  final bool secondaryEnable;
  final bool? isSecondaryLoading;
  final bool? isLoading;

  @override
  State<AppTwoButtons> createState() => _AppTwoButtonsState();
}

class _AppTwoButtonsState extends State<AppTwoButtons> {
  bool _internalPrimaryLoading = false;
  bool _internalSecondaryLoading = false;

  bool get _isPrimaryLoading =>
      widget.isLoading ?? widget.isPrimaryLoading ?? _internalPrimaryLoading;
  bool get _isSecondaryLoading =>
      widget.isSecondaryLoading ?? _internalSecondaryLoading;
  bool get _isAnyLoading => _isPrimaryLoading || _isSecondaryLoading;

  Future<void> _runAction({
    required bool enabled,
    required FutureOr<dynamic> Function()? callback,
    required void Function(bool loading) setLoading,
  }) async {
    if (_isAnyLoading || !enabled || callback == null) return;
    setState(() => setLoading(true));
    try {
      final result = callback();
      if (result is Future) {
        await result;
      }
    } finally {
      if (mounted) {
        setState(() => setLoading(false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrimaryInteractive =
        widget.primaryEnable && !_isAnyLoading && widget.primaryOnTap != null;
    final hasSecondary =
        widget.secondaryTitle != null &&
        widget.secondaryTitle!.trim().isNotEmpty;
    final isSecondaryInteractive =
        widget.secondaryEnable &&
        !_isAnyLoading &&
        widget.secondaryOnTap != null;
    return AppGlass(
      borderRadius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isPrimaryInteractive
                  ? () => _runAction(
                      enabled: widget.primaryEnable,
                      callback: widget.primaryOnTap,
                      setLoading: (v) => _internalPrimaryLoading = v,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryEnable
                    ? UIColors.primary
                    : UIColors.disabled,
                disabledBackgroundColor: widget.primaryEnable
                    ? (_isPrimaryLoading
                          ? UIColors.primary
                          : UIColors.primary.withValues(alpha: 0.6))
                    : UIColors.disabled,
                foregroundColor: UIColors.bg,
                disabledForegroundColor: UIColors.bg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isPrimaryLoading
                    ? const SizedBox(
                        key: ValueKey('primary_loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            UIColors.bg,
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('primary_content'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.primaryIcon != null) ...[
                            AppIcon(
                              widget.primaryIcon!,
                              size: 18,
                              color: UIColors.bg,
                            ),
                            const Gap(8),
                          ],
                          AppText.bold(
                            widget.primaryTitle,
                            size: 15,
                            color: UIColors.bg,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (hasSecondary) ...[
            const Gap(8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: isSecondaryInteractive
                    ? () => _runAction(
                        enabled: widget.secondaryEnable,
                        callback: widget.secondaryOnTap,
                        setLoading: (v) => _internalSecondaryLoading = v,
                      )
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: UIColors.textSecondary,
                  disabledForegroundColor: UIColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSecondaryLoading
                      ? const SizedBox(
                          key: ValueKey('secondary_loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              UIColors.textSecondary,
                            ),
                          ),
                        )
                      : Row(
                          key: const ValueKey('secondary_content'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.secondaryIcon != null) ...[
                              AppIcon(
                                widget.secondaryIcon!,
                                size: 16,
                                color: UIColors.textSecondary,
                              ),
                              const Gap(8),
                            ],
                            AppText.semiBold(
                              widget.secondaryTitle!,
                              size: 14,
                              color: UIColors.textSecondary,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
