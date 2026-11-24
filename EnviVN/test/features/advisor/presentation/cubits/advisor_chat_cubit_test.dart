import 'package:flutter_test/flutter_test.dart';

import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/infrastructure/services/edge_ai_inference_service.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_chat_cubit.dart';

class _StubChatBridge implements IAiChatBridge {
  bool shouldError = false;
  List<Map<String, String>> capturedHistory = const [];

  @override
  Future<void> startSession({double? lat, double? lon}) async {}

  @override
  Stream<String> generateResponseStream(
    String message, {
    List<Map<String, String>> history = const [],
  }) async* {
    capturedHistory = history;
    if (shouldError) throw Exception('offline');
    yield 'Thời tiết phù hợp ';
    yield 'để chạy bộ nhẹ.';
  }

  @override
  Future<String> generateResponse(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    capturedHistory = history;
    return 'Thời tiết phù hợp để chạy bộ nhẹ.';
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubChatBridge bridge;
  late EdgeAiInferenceService inferenceService;
  late AdvisorChatCubit chatCubit;

  setUp(() {
    bridge = _StubChatBridge();
    inferenceService = EdgeAiInferenceService(bridge: bridge);
    chatCubit = AdvisorChatCubit(inferenceService: inferenceService);
  });

  tearDown(() async {
    await chatCubit.close();
    await inferenceService.dispose();
  });

  group('AdvisorChatCubit Tests', () {
    test('initial state has isAiEnabled false and default questions', () {
      expect(chatCubit.state.isAiEnabled, isFalse);
      expect(chatCubit.state.messages, isEmpty);
      expect(chatCubit.state.suggestedQuestions, isNotEmpty);
    });

    test('toggleAi toggles AI enabled status', () {
      chatCubit.toggleAi(true);
      expect(chatCubit.state.isAiEnabled, isTrue);
      chatCubit.toggleAi(false);
      expect(chatCubit.state.isAiEnabled, isFalse);
    });

    test('initChat populates welcome message with location name', () async {
      final location = AppLocationEntity.city(
        name: 'Hà Nội',
        province: 'Hà Nội',
        latitude: 21.0285,
        longitude: 105.8542,
      );
      await chatCubit.initChat(location: location);
      expect(chatCubit.state.messages.length, equals(1));
      expect(chatCubit.state.messages.first.isUser, isFalse);
      expect(chatCubit.state.messages.first.text, contains('Hà Nội'));
    });

    test(
      'sendMessage appends user message, streams bot reply, and passes multi-turn history on follow-up',
      () async {
        final location = AppLocationEntity.city(
          name: 'Đà Nẵng',
          province: 'Đà Nẵng',
          latitude: 16.0544,
          longitude: 108.2022,
        );
        await chatCubit.initChat(location: location);
        await chatCubit.sendMessage('Có nên chạy bộ không?');
        expect(bridge.capturedHistory, isEmpty);
        expect(chatCubit.state.messages.length, equals(3));
        expect(chatCubit.state.messages[1].isUser, isTrue);
        expect(chatCubit.state.messages[2].text, contains('chạy bộ'));
        await chatCubit.sendMessage('Vậy cần mang nước không?');
        expect(bridge.capturedHistory.length, equals(2));
        expect(bridge.capturedHistory[0], {
          'role': 'user',
          'content': 'Có nên chạy bộ không?',
        });
        expect(bridge.capturedHistory[1]['role'], 'assistant');
      },
    );

    test('clearChat resets messages and re-initializes chat session', () async {
      final location = AppLocationEntity.city(
        name: 'TP. Hồ Chí Minh',
        province: 'TP. Hồ Chí Minh',
        latitude: 10.7769,
        longitude: 106.7009,
      );
      await chatCubit.initChat(location: location);
      await chatCubit.sendMessage('Xin chào');
      expect(chatCubit.state.messages.length, greaterThanOrEqualTo(2));
      chatCubit.clearChat(location: location);
      await pumpEventQueue();
      expect(chatCubit.state.messages.length, equals(1));
    });

    test(
      'sendMessage surfaces errorMessage on backend failure instead of faking reply',
      () async {
        final location = AppLocationEntity.defaultLocation;
        await chatCubit.initChat(location: location);
        bridge.shouldError = true;
        await chatCubit.sendMessage('Hỏi thời tiết');
        expect(chatCubit.state.isStreaming, isFalse);
        expect(chatCubit.state.errorMessage, isNotNull);
        expect(
          chatCubit.state.messages.last.text,
          contains('Không thể kết nối'),
        );
      },
    );
  });
}
