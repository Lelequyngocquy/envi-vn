import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:envivn/src/core/infrastructure/configs/env_config.dart';
import 'package:envivn/src/core/infrastructure/services/edge_ai_inference_service.dart';

class _FakeChatBridge implements IAiChatBridge {
  double? lastLat;
  double? lastLon;
  List<Map<String, String>> lastHistory = const [];
  bool closed = false;
  List<String> chunks = const ['Xin ', 'chào ', 'EnviVN!'];

  @override
  Future<void> startSession({double? lat, double? lon}) async {
    lastLat = lat;
    lastLon = lon;
  }

  @override
  Stream<String> generateResponseStream(
    String message, {
    List<Map<String, String>> history = const [],
  }) async* {
    lastHistory = history;
    for (final chunk in chunks) {
      await Future<void>.delayed(Duration.zero);
      yield chunk;
    }
  }

  @override
  Future<String> generateResponse(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    lastHistory = history;
    return chunks.join();
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackendSseBridge Tests', () {
    setUp(() {
      EnvConfig.reset();
      EnvConfig.loadFromString(
        'BACKEND_BASE_URL=http://localhost:8080\nCLIENT_API_KEY=chat-key-99',
      );
    });

    test(
      'streams UTF-8 SSE chunks, sends multi-turn history, attaches x-api-key, and strips system role',
      () async {
        Map<String, dynamic>? capturedBody;
        Uri? capturedUri;
        String? capturedApiKey;
        final mockClient = MockClient.streaming((request, bodyStream) async {
          capturedUri = request.url;
          capturedApiKey = request.headers['x-api-key'];
          final rawBody = await bodyStream.bytesToString();
          capturedBody = jsonDecode(rawBody) as Map<String, dynamic>;
          final payload =
              'data: {"content":"Thời tiết ","done":false}\n\n'
              'data: not-valid-json\n'
              'data: {"content":"trong lành.","done":false}\n'
              'data: [DONE]\n'
              'data: {"content":"ignored","done":false}\n';
          final bytes = utf8.encode(payload);
          final split = bytes.length ~/ 2;
          return http.StreamedResponse(
            Stream<List<int>>.fromIterable([
              bytes.sublist(0, split),
              bytes.sublist(split),
            ]),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        });
        final bridge = BackendSseBridge(client: mockClient);
        await bridge.startSession(lat: 21.0285, lon: 105.8542);
        final chunks = await bridge
            .generateResponseStream(
              'Vậy tối nay có mưa không?',
              history: const [
                {'role': 'system', 'content': 'inject override'},
                {'role': 'user', 'content': 'Hôm nay AQI thế nào?'},
                {'role': 'assistant', 'content': 'AQI đang ở mức Tốt.'},
              ],
            )
            .toList();
        expect(
          capturedUri.toString(),
          'http://localhost:8080/api/v1/advisor/chat',
        );
        expect(capturedApiKey, 'chat-key-99');
        expect(capturedBody?['message'], 'Vậy tối nay có mưa không?');
        expect(capturedBody?['lat'], 21.0285);
        expect(capturedBody?['lon'], 105.8542);
        expect(capturedBody?.containsKey('system'), isFalse);
        final sentMessages = (capturedBody?['messages'] as List)
            .cast<Map<String, dynamic>>();
        expect(sentMessages.length, 3);
        expect(sentMessages.any((m) => m['role'] == 'system'), isFalse);
        expect(sentMessages.first['role'], 'user');
        expect(sentMessages.last['content'], 'Vậy tối nay có mưa không?');
        expect(chunks, ['Thời tiết ', 'trong lành.']);
        await bridge.close();
      },
    );

    test('generateResponse concatenates full streamed SSE response', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        const payload =
            'data: {"content":"AQI ","done":false}\ndata: {"content":"tốt","done":false}\ndata: [DONE]\n';
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode(payload)),
          200,
        );
      });
      final bridge = BackendSseBridge(client: mockClient);
      await bridge.startSession(lat: 16.05, lon: 108.20);
      final text = await bridge.generateResponse('Hỏi AQI');
      expect(text, 'AQI tốt');
      await bridge.close();
    });

    test(
      'drains response stream and throws ClientException on non-200 status',
      () async {
        bool drained = false;
        final mockClient = MockClient.streaming((request, bodyStream) async {
          await bodyStream.drain<void>();
          final stream =
              Stream<List<int>>.fromIterable([
                utf8.encode('Upstream error'),
              ]).map((chunk) {
                drained = true;
                return chunk;
              });
          return http.StreamedResponse(stream, 502);
        });
        final bridge = BackendSseBridge(client: mockClient);
        await expectLater(
          bridge.generateResponseStream('Xin chào').toList(),
          throwsA(isA<http.ClientException>()),
        );
        expect(drained, isTrue);
        await bridge.close();
      },
    );
  });

  group('EdgeAiInferenceService Tests', () {
    late _FakeChatBridge bridge;
    late EdgeAiInferenceService service;

    setUp(() {
      bridge = _FakeChatBridge();
      service = EdgeAiInferenceService(bridge: bridge);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('throws StateError when sending before startChatSession', () {
      expect(() => service.sendMessage('test'), throwsStateError);
      expect(
        () => service.sendMessageStream('test').toList(),
        throwsStateError,
      );
    });

    test(
      'startChatSession forwards coordinates, history, and streams chunks',
      () async {
        await service.startChatSession(lat: 10.77, lon: 106.70);
        expect(service.isChatActive, isTrue);
        expect(bridge.lastLat, 10.77);
        expect(bridge.lastLon, 106.70);
        const history = [
          {'role': 'user', 'content': 'Hi'},
        ];
        final chunks = await service
            .sendMessageStream('Chạy bộ?', history: history)
            .toList();
        expect(bridge.lastHistory, history);
        expect(chunks.join(), 'Xin chào EnviVN!');
        expect(await service.sendMessage('Chạy bộ?'), 'Xin chào EnviVN!');
      },
    );

    test(
      'resetChatSession updates coordinates and dispose closes bridge',
      () async {
        await service.startChatSession(lat: 21.0, lon: 105.0);
        await service.resetChatSession(lat: 16.0, lon: 108.0);
        expect(bridge.lastLat, 16.0);
        expect(bridge.lastLon, 108.0);
        await service.dispose();
        expect(service.isChatActive, isFalse);
        expect(bridge.closed, isTrue);
      },
    );
  });
}
