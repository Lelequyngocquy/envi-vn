import 'package:flutter/material.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/app_icon.dart';

/// Reusable concentric radar rings illustration with a highlighted center badge.
class RadarIllustrationWidget extends StatelessWidget {
  final IconData centerIcon;

  const RadarIllustrationWidget({super.key, required this.centerIcon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(220, 0.18),
            _ring(160, 0.32),
            _ring(104, 0.48),
            Positioned(
              top: 36,
              right: 48,
              child: _glowDot(8, UIColors.secondary, blur: 8, spread: 2),
            ),
            Positioned(
              bottom: 46,
              left: 54,
              child: _glowDot(6, UIColors.warning, blur: 6, spread: 1),
            ),
            Positioned(
              bottom: 68,
              child: Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: UIColors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: UIColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: UIColors.primary.withValues(alpha: 0.6),
                    blurRadius: 26,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: AppIcon(centerIcon, size: 30, color: UIColors.bg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: UIColors.primary.withValues(alpha: alpha),
          width: 2,
        ),
      ),
    );
  }

  Widget _glowDot(
    double size,
    Color color, {
    required double blur,
    required double spread,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.8),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
    );
  }
}
