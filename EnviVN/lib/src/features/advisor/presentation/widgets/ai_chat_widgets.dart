import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../cubits/advisor_chat_state.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageItem message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: UIColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: UIColors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: const AppIcon(
                Icons.auto_awesome,
                size: 14,
                color: UIColors.primary,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? UIColors.primary.withValues(alpha: 0.20)
                    : UIColors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? UIColors.primary.withValues(alpha: 0.40)
                      : UIColors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    const AppText.bold(
                      'Cố vấn AI EnviVN',
                      size: 11,
                      color: UIColors.primary,
                    ),
                    const Gap(4),
                  ],
                  if (message.text.isEmpty && message.isStreaming)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: UIColors.primary,
                          ),
                        ),
                        Gap(8),
                        AppText.regular(
                          'Đang suy luận...',
                          size: 12,
                          color: UIColors.textSecondary,
                        ),
                      ],
                    )
                  else
                    AppText.regular(
                      message.text,
                      size: 13,
                      color: UIColors.textPrimary,
                      height: 1.45,
                    ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: UIColors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 14,
                color: UIColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class ChatSuggestedQuestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const ChatSuggestedQuestionChip({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: UIColors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UIColors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 13,
              color: UIColors.primary,
            ),
            const Gap(6),
            AppText.regular(question, size: 11.5, color: UIColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: UIColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: UIColors.white.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isStreaming,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: UIColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Hỏi về không khí, chạy bộ, ngập úng...',
                hintStyle: TextStyle(
                  color: UIColors.textSecondary,
                  fontSize: 12.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: isStreaming ? null : onSend,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isStreaming
                    ? UIColors.white.withValues(alpha: 0.12)
                    : UIColors.primary,
                shape: BoxShape.circle,
              ),
              child: isStreaming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: UIColors.textSecondary,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: UIColors.bg,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
