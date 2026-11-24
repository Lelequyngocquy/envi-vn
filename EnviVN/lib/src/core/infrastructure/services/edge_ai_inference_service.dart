import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configs/env_config.dart';

abstract class IAiChatBridge {
  Future<void> startSession({double? lat, double? lon});
  Stream<String> generateResponseStream(String message);
  Future<String> generateResponse(String message);
  Future<void> close();
}

class BackendSseBridge implements IAiChatBridge {
  final http.Client _client;
  final bool _ownsClient;
  double? _latitude;
  double? _longitude;

  BackendSseBridge({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  Future<void> startSession({double? lat, double? lon}) async {
    _latitude = lat;
    _longitude = lon;
  }

  @override
  Stream<String> generateResponseStream(String message) async* {
    final uri = Uri.parse('${EnvConfig.backendBaseUrl}/api/v1/advisor/chat');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    // Never send client-controlled system prompts to backend.
    request.body = jsonEncode({
      'message': message,
      if (_latitude != null) 'lat': _latitude,
      if (_longitude != null) 'lon': _longitude,
    });
    final response = await _client.send(request).timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw http.ClientException('Backend returned status ${response.statusCode}', uri);
    }
    await for (final line in response.stream.toStringStream().transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map && decoded['content'] is String) {
            final content = decoded['content'] as String;
            if (content.isNotEmpty) yield content;
          }
        } catch (_) {}
      }
    }
  }

  @override
  Future<String> generateResponse(String message) async {
    final buffer = StringBuffer();
    await for (final chunk in generateResponseStream(message)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  @override
  Future<void> close() async {
    if (_ownsClient) _client.close();
  }
}

class EdgeAiInferenceService {
  final IAiChatBridge _bridge;
  bool _isChatActive = false;

  EdgeAiInferenceService({IAiChatBridge? bridge}) : _bridge = bridge ?? BackendSseBridge();

  bool get isChatActive => _isChatActive;

  Future<void> startChatSession({double? lat, double? lon}) async {
    await _bridge.startSession(lat: lat, lon: lon);
    _isChatActive = true;
  }

  Stream<String> sendMessageStream(String userMessage) async* {
    if (!_isChatActive) {
      throw StateError('Please call startChatSession before sending messages.');
    }
    yield* _bridge.generateResponseStream(userMessage);
  }

  Future<String> sendMessage(String userMessage) async {
    if (!_isChatActive) {
      throw StateError('Please call startChatSession before sending messages.');
    }
    return _bridge.generateResponse(userMessage);
  }

  Future<void> resetChatSession({double? lat, double? lon}) async {
    await _bridge.startSession(lat: lat, lon: lon);
    _isChatActive = true;
  }

  Future<void> dispose() async {
    _isChatActive = false;
    await _bridge.close();
  }
}
