import 'package:flutter/material.dart';

import '../../domain/entities/quick_prompt_type.dart';
import '../../domain/entities/safety_level.dart';

extension SafetyLevelUiX on SafetyLevel {
  Color get color {
    switch (this) {
      case SafetyLevel.safe:
        return const Color(0xFF00E676);
      case SafetyLevel.caution:
        return const Color(0xFFFFD600);
      case SafetyLevel.warning:
        return const Color(0xFFFF9100);
      case SafetyLevel.danger:
        return const Color(0xFFFF1744);
    }
  }

  IconData get icon {
    switch (this) {
      case SafetyLevel.safe:
        return Icons.check_circle_rounded;
      case SafetyLevel.caution:
        return Icons.info_rounded;
      case SafetyLevel.warning:
        return Icons.warning_rounded;
      case SafetyLevel.danger:
        return Icons.dangerous_rounded;
    }
  }
}

extension QuickPromptTypeUiX on QuickPromptType {
  IconData get icon {
    switch (this) {
      case QuickPromptType.running:
        return Icons.directions_run_rounded;
      case QuickPromptType.ventilation:
        return Icons.air_rounded;
      case QuickPromptType.childrenOutdoor:
        return Icons.family_restroom_rounded;
      case QuickPromptType.commute:
        return Icons.two_wheeler_rounded;
    }
  }
}
