import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../domain/entities/quick_prompt_type.dart';
import '../extensions/advisor_ui_extensions.dart';

/// Toggle bar switching between rule-based WHO/EPA mode and Local AI Node chat.
class AdvisorModeToggleBar extends StatelessWidget {
  final bool isAiEnabled;
  final ValueChanged<bool> onToggle;

  const AdvisorModeToggleBar({
    super.key,
    required this.isAiEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: UIColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAiEnabled
              ? UIColors.primary.withValues(alpha: 0.4)
              : UIColors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (isAiEnabled ? UIColors.primary : UIColors.textSecondary)
                  .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: isAiEnabled ? UIColors.primary : UIColors.textSecondary,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bold(
                  'Trợ lý AI EnviVN',
                  size: 13,
                  color: isAiEnabled
                      ? UIColors.textPrimary
                      : UIColors.textSecondary,
                ),
                const Gap(1),
                AppText.regular(
                  isAiEnabled
                      ? 'Local AI Node • Phản hồi thông minh'
                      : 'Quy tắc cố định WHO/EPA (0ms)',
                  size: 10.5,
                  color: UIColors.textSecondary,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isAiEnabled,
            onChanged: onToggle,
            activeThumbColor: UIColors.primary,
            activeTrackColor: UIColors.primary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

/// Selectable quick-prompt chip displayed at the bottom of rule-based Advisor mode.
class AdvisorPromptChip extends StatelessWidget {
  final QuickPromptType prompt;
  final bool isSelected;
  final VoidCallback onTap;

  const AdvisorPromptChip({
    super.key,
    required this.prompt,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? UIColors.primary
              : UIColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? UIColors.primary
                : UIColors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: UIColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              prompt.icon,
              size: 16,
              color: isSelected ? UIColors.bg : UIColors.textPrimary,
            ),
            const Gap(8),
            AppText.bold(
              prompt.label,
              size: 12.5,
              color: isSelected ? UIColors.bg : UIColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
