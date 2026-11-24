import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/app_location_entity.dart';
import '../../../../core/domain/entities/model_download_state.dart';
import '../../../../core/infrastructure/datasources/local/local_storage.dart';
import '../../../../core/infrastructure/services/context_prompt_builder.dart';
import '../../../../core/infrastructure/services/edge_ai_inference_service.dart';
import '../../../../core/infrastructure/services/model_download_service.dart';
import '../../../air_quality/domain/entities/air_quality_entity.dart';
import '../../../details/domain/entities/details_entity.dart';
import 'advisor_chat_state.dart';

class AdvisorChatCubit extends Cubit<AdvisorChatState> {
  final ModelDownloadService downloadService;
  final EdgeAiInferenceService inferenceService;
  final LocalStorage localStorage;

  StreamSubscription<ModelDownloadState>? _downloadSub;
  StreamSubscription<String>? _streamSub;
  Completer<void>? _activeCompleter;

  AdvisorChatCubit({
    required this.downloadService,
    required this.inferenceService,
    required this.localStorage,
  }) : super(AdvisorChatState(downloadState: downloadService.currentState)) {
    _downloadSub = downloadService.stateStream.listen((dState) {
      if (isClosed) return;
      emit(state.copyWith(downloadState: dState));
    });
  }

  void toggleAi(bool enabled) {
    if (isClosed) return;
    emit(state.copyWith(isAiEnabled: enabled));
  }

  Future<void> initChat({
    required AppLocationEntity location,
    required DetailsEntity weather,
    required AirQualityEntity airQuality,
  }) async {
    await downloadService.init();
    if (isClosed) return;
    final isReady = await downloadService.isModelReady();
    if (isClosed) return;
    if (!isReady) {
      final canInit = await inferenceService.initModel();
      if (isClosed || !canInit) return;
      emit(state.copyWith(downloadState: const ModelDownloadState(status: ModelDownloadStatus.ready, progress: 1.0)));
    }
    final hasEnoughRam = await inferenceService.hasEnoughRam();
    if (isClosed) return;
    if (!hasEnoughRam) {
      emit(state.copyWith(errorMessage: 'Thiết bị còn ít hơn 1.4 GB RAM trống. Vui lòng đóng bớt ứng dụng nền hoặc sử dụng chế độ Cố vấn Tiêu chuẩn.', isAiEnabled: false));
      return;
    }
    final systemPrompt = ContextPromptBuilder.buildSystemPrompt(location: location, weather: weather, airQuality: airQuality);
    try {
      await inferenceService.startChatSession(systemPrompt: systemPrompt, lat: location.latitude, lon: location.longitude);
      if (isClosed) return;
      if (state.messages.isEmpty) {
        final greeting = ChatMessageItem(id: 'welcome_${DateTime.now().millisecondsSinceEpoch}', text: 'Xin chào! Tôi là Trợ lý AI EnviVN. Tôi đã nạp toàn bộ dữ liệu môi trường và thời tiết tại ${location.displayName}. Bạn cần tôi tư vấn điều gì?', isUser: false, timestamp: DateTime.now());
        emit(state.copyWith(messages: [greeting], clearError: true));
      }
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: 'Không thể khởi chạy phiên trợ lý AI lúc này.'));
    }
  }

  Future<void> startDownload() async {
    await downloadService.startDownload();
  }

  Future<void> pauseDownload() async {
    await downloadService.pauseDownload();
  }

  Future<void> resumeDownload() async {
    await downloadService.resumeDownload();
  }

  Future<void> cancelDownload() async {
    await downloadService.cancelDownload();
  }

  Future<void> deleteModel() async {
    await downloadService.deleteModel();
    if (isClosed) return;
    emit(state.copyWith(messages: []));
  }

  void _completeActiveStream() {
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
    }
    _activeCompleter = null;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming || isClosed) return;
    final userMsg = ChatMessageItem(id: 'user_${DateTime.now().millisecondsSinceEpoch}', text: trimmed, isUser: true, timestamp: DateTime.now());
    final botMsgId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final botMsg = ChatMessageItem(id: botMsgId, text: '', isUser: false, timestamp: DateTime.now(), isStreaming: true);
    final updatedMessages = List<ChatMessageItem>.from(state.messages)..add(userMsg)..add(botMsg);
    emit(state.copyWith(messages: updatedMessages, isStreaming: true, clearError: true));
    final buffer = StringBuffer();
    final completer = Completer<void>();
    _activeCompleter = completer;
    const errorFallbackText = 'Không thể kết nối máy chủ AI lúc này. Vui lòng kiểm tra kết nối và thử lại.';
    try {
      await _streamSub?.cancel();
      if (isClosed) {
        _completeActiveStream();
        return;
      }
      _streamSub = inferenceService.sendMessageStream(trimmed).listen(
        (chunk) {
          if (isClosed) return;
          buffer.write(chunk);
          final currentList = List<ChatMessageItem>.from(state.messages);
          final index = currentList.indexWhere((m) => m.id == botMsgId);
          if (index != -1) {
            currentList[index] = currentList[index].copyWith(text: buffer.toString());
            emit(state.copyWith(messages: currentList));
          }
        },
        onDone: () {
          if (!isClosed) {
            final currentList = List<ChatMessageItem>.from(state.messages);
            final index = currentList.indexWhere((m) => m.id == botMsgId);
            if (index != -1) {
              currentList[index] = currentList[index].copyWith(text: buffer.toString(), isStreaming: false);
              emit(state.copyWith(messages: currentList, isStreaming: false));
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
              currentList[index] = currentList[index].copyWith(text: buffer.isNotEmpty ? buffer.toString() : errorFallbackText, isStreaming: false);
              emit(state.copyWith(messages: currentList, isStreaming: false, errorMessage: errorFallbackText));
            } else {
              emit(state.copyWith(isStreaming: false, errorMessage: errorFallbackText));
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
          currentList[index] = currentList[index].copyWith(text: errorFallbackText, isStreaming: false);
          emit(state.copyWith(messages: currentList, isStreaming: false, errorMessage: errorFallbackText));
        } else {
          emit(state.copyWith(isStreaming: false, errorMessage: errorFallbackText));
        }
      }
      _completeActiveStream();
    }
  }

  void clearChat({
    required AppLocationEntity location,
    required DetailsEntity weather,
    required AirQualityEntity airQuality,
  }) {
    _streamSub?.cancel();
    _streamSub = null;
    _completeActiveStream();
    if (isClosed) return;
    emit(state.copyWith(messages: [], isStreaming: false, clearError: true));
    initChat(location: location, weather: weather, airQuality: airQuality);
  }

  @override
  Future<void> close() async {
    await _downloadSub?.cancel();
    await _streamSub?.cancel();
    _completeActiveStream();
    return super.close();
  }
}
