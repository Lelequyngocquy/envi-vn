import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/app_location_entity.dart';
import '../../../../core/domain/interfaces/i_ai_chat_service.dart';
import 'advisor_chat_state.dart';

class AdvisorChatCubit extends Cubit<AdvisorChatState> {
  static const int _maxHistoryTurns = 8;

  final IAiChatService inferenceService;
  StreamSubscription<String>? _streamSub;
  Completer<void>? _activeCompleter;

  AdvisorChatCubit({required this.inferenceService})
    : super(const AdvisorChatState());

  void toggleAi(bool enabled) {
    if (isClosed) return;
    emit(state.copyWith(isAiEnabled: enabled));
  }

  Future<void> initChat({required AppLocationEntity location}) async {
    try {
      await inferenceService.startChatSession(
        lat: location.latitude,
        lon: location.longitude,
      );
      if (isClosed) return;
      if (state.messages.isEmpty) {
        final greeting = ChatMessageItem(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Xin chào! Tôi là Trợ lý AI EnviVN. Tôi đã sẵn sàng phân tích dữ liệu môi trường và thời tiết tại ${location.displayName}. Bạn cần tôi tư vấn điều gì?',
          isUser: false,
          timestamp: DateTime.now(),
        );
        emit(state.copyWith(messages: [greeting], clearError: true));
      }
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          errorMessage: 'Không thể khởi chạy phiên trợ lý AI lúc này.',
        ),
      );
    }
  }

  void _completeActiveStream() {
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
    }
    _activeCompleter = null;
  }

  List<Map<String, String>> _buildRecentHistory() {
    final history = <Map<String, String>>[];
    for (final msg in state.messages) {
      if (msg.id.startsWith('welcome_') || msg.isStreaming) continue;
      final content = msg.text.trim();
      if (content.isEmpty) continue;
      history.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': content,
      });
    }
    if (history.length > _maxHistoryTurns) {
      return history.sublist(history.length - _maxHistoryTurns);
    }
    return history;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming || isClosed) return;
    final recentHistory = _buildRecentHistory();
    final userMsg = ChatMessageItem(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    final botMsgId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final botMsg = ChatMessageItem(
      id: botMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    final updatedMessages = List<ChatMessageItem>.from(state.messages)
      ..add(userMsg)
      ..add(botMsg);
    emit(
      state.copyWith(
        messages: updatedMessages,
        isStreaming: true,
        clearError: true,
      ),
    );
    final buffer = StringBuffer();
    final completer = Completer<void>();
    _activeCompleter = completer;
    const errorFallbackText =
        'Không thể kết nối máy chủ AI lúc này. Vui lòng kiểm tra kết nối và thử lại.';
    try {
      await _streamSub?.cancel();
      if (isClosed) {
        _completeActiveStream();
        return;
      }
      _streamSub = inferenceService
          .sendMessageStream(trimmed, history: recentHistory)
          .listen(
            (chunk) {
              if (isClosed) return;
              buffer.write(chunk);
              final currentList = List<ChatMessageItem>.from(state.messages);
              final index = currentList.indexWhere((m) => m.id == botMsgId);
              if (index != -1) {
                currentList[index] = currentList[index].copyWith(
                  text: buffer.toString(),
                );
                emit(state.copyWith(messages: currentList));
              }
            },
            onDone: () {
              if (!isClosed) {
                final currentList = List<ChatMessageItem>.from(state.messages);
                final index = currentList.indexWhere((m) => m.id == botMsgId);
                if (index != -1) {
                  currentList[index] = currentList[index].copyWith(
                    text: buffer.toString(),
                    isStreaming: false,
                  );
                  emit(
                    state.copyWith(messages: currentList, isStreaming: false),
                  );
                } else {
                  emit(state.copyWith(isStreaming: false));
                }
              }
              _completeActiveStream();
            },
            onError: (_) {
              if (!isClosed) {
                final currentList = List<ChatMessageItem>.from(state.messages);
                final index = currentList.indexWhere((m) => m.id == botMsgId);
                if (index != -1) {
                  currentList[index] = currentList[index].copyWith(
                    text: buffer.isNotEmpty
                        ? buffer.toString()
                        : errorFallbackText,
                    isStreaming: false,
                  );
                  emit(
                    state.copyWith(
                      messages: currentList,
                      isStreaming: false,
                      errorMessage: errorFallbackText,
                    ),
                  );
                } else {
                  emit(
                    state.copyWith(
                      isStreaming: false,
                      errorMessage: errorFallbackText,
                    ),
                  );
                }
              }
              _completeActiveStream();
            },
            cancelOnError: true,
          );
      await completer.future;
    } catch (_) {
      if (!isClosed) {
        final currentList = List<ChatMessageItem>.from(state.messages);
        final index = currentList.indexWhere((m) => m.id == botMsgId);
        if (index != -1) {
          currentList[index] = currentList[index].copyWith(
            text: errorFallbackText,
            isStreaming: false,
          );
          emit(
            state.copyWith(
              messages: currentList,
              isStreaming: false,
              errorMessage: errorFallbackText,
            ),
          );
        } else {
          emit(
            state.copyWith(isStreaming: false, errorMessage: errorFallbackText),
          );
        }
      }
      _completeActiveStream();
    }
  }

  void clearChat({required AppLocationEntity location}) {
    _streamSub?.cancel();
    _streamSub = null;
    _completeActiveStream();
    if (isClosed) return;
    emit(state.copyWith(messages: [], isStreaming: false, clearError: true));
    initChat(location: location);
  }

  @override
  Future<void> close() async {
    await _streamSub?.cancel();
    _completeActiveStream();
    return super.close();
  }
}
