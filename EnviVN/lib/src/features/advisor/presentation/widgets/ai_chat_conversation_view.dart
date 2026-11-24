import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../common/constants/colors.dart';
import '../../../../core/domain/entities/air_quality_entity.dart';
import '../../../../core/domain/entities/app_location_entity.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../../../core/presentation/widgets/app_icon.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../cubits/advisor_chat_cubit.dart';
import '../cubits/advisor_chat_state.dart';
import 'ai_chat_widgets.dart';

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
  DateTime _lastStreamScrollAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    final now = DateTime.now();
    if (immediate && now.difference(_lastStreamScrollAt).inMilliseconds < 80) {
      return;
    }
    _lastStreamScrollAt = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (immediate) {
        _scrollController.jumpTo(maxExtent);
      } else {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 220),
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
      listenWhen: (prev, curr) {
        if (prev.messages.length != curr.messages.length) return true;
        if (curr.messages.isEmpty || prev.messages.isEmpty) return false;
        return curr.isStreaming &&
            prev.messages.last.text.length != curr.messages.last.text.length;
      },
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom(immediate: state.isStreaming);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: UIColors.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: UIColors.error.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const AppIcon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: UIColors.error,
                    ),
                    const Gap(8),
                    Expanded(
                      child: AppText.regular(
                        state.errorMessage!,
                        size: 11.5,
                        color: UIColors.textPrimary,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.messages.length,
                itemBuilder: (context, index) =>
                    ChatMessageBubble(message: state.messages[index]),
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
                    return ChatSuggestedQuestionChip(
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
            ChatInputBar(
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
