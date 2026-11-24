import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/domain/entities/app_location_entity.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../air_quality/domain/entities/air_quality_entity.dart';
import '../../../details/domain/entities/details_entity.dart';
import '../cubits/advisor_chat_cubit.dart';
import '../cubits/advisor_chat_state.dart';

class AiChatConversationView extends StatefulWidget {
  final AppLocationEntity location;
  final DetailsEntity weather;
  final AirQualityEntity airQuality;

  const AiChatConversationView({
    super.key,
    required this.location,
    required this.weather,
    required this.airQuality,
  });

  @override
  State<AiChatConversationView> createState() => _AiChatConversationViewState();
}

class _AiChatConversationViewState extends State<AiChatConversationView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    context.read<AdvisorChatCubit>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdvisorChatCubit, AdvisorChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: UIColors.error.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: UIColors.error.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    const AppIcon(Icons.error_outline_rounded, size: 16, color: UIColors.error),
                    const Gap(8),
                    Expanded(child: AppText.regular(state.errorMessage!, size: 11.5, color: UIColors.textPrimary, maxLines: 3)),
                  ],
                ),
              ),
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            if (state.suggestedQuestions.isNotEmpty && !state.isStreaming) ...[
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: state.suggestedQuestions.length,
                  separatorBuilder: (_, _) => const Gap(8),
                  itemBuilder: (context, index) {
                    final question = state.suggestedQuestions[index];
                    return _SuggestedQuestionChip(
                      question: question,
                      onTap: () {
                        context.read<AdvisorChatCubit>().sendMessage(question);
                        _scrollToBottom();
                      },
                    );
                  },
                ),
              ),
              const Gap(10),
            ],
            _InputBar(
              controller: _textController,
              isStreaming: state.isStreaming,
              onSend: _sendMessage,
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageItem message;

  const _MessageBubble({required this.message});

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
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: UIColors.primary.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: UIColors.primary.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: const AppIcon(
                Icons.auto_awesome,
                size: 14,
                color: UIColors.primary,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? UIColors.primary.withOpacity(0.20)
                    : UIColors.white.withOpacity(0.07),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? UIColors.primary.withOpacity(0.40)
                      : UIColors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        AppText.bold(
                          'Cố vấn AI EnviVN',
                          size: 11,
                          color: UIColors.primary,
                        ),
                      ],
                    ),
                    const Gap(4),
                  ],
                  if (message.text.isEmpty && message.isStreaming)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
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
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: UIColors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 14,
                color: UIColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestedQuestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _SuggestedQuestionChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: UIColors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UIColors.white.withOpacity(0.14)),
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

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: UIColors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: UIColors.white.withOpacity(0.14), width: 1),
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
                    ? UIColors.white.withOpacity(0.12)
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
