import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../configs/env_config.dart';
import 'context_prompt_builder.dart';
import 'model_download_service.dart';

abstract class IGemmaBridge {
  Future<bool> isModelInstalled();
  Future<void> setModelPath(String path);
  Future<void> createModel({required bool isInstructionTuned, int maxTokens});
  Future<void> createChatSession({String? systemPrompt});
  Stream<String> generateResponseAsync(String message);
  Future<String> generateResponse(String message);
  Future<void> close();
}

class BackendSseBridge implements IGemmaBridge {
  final http.Client _client;
  String? _systemPrompt;
  double? latitude;
  double? longitude;

  BackendSseBridge({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<bool> isModelInstalled() async => true;

  @override
  Future<void> setModelPath(String path) async {}

  @override
  Future<void> createModel({required bool isInstructionTuned, int maxTokens = 2048}) async {}

  @override
  Future<void> createChatSession({String? systemPrompt}) async {
    _systemPrompt = systemPrompt;
  }

  @override
  Stream<String> generateResponseAsync(String message) async* {
    final uri = Uri.parse('${EnvConfig.backendBaseUrl}/api/v1/advisor/chat');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'message': message,
      if (_systemPrompt != null) 'system': _systemPrompt,
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lon': longitude,
    });
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw HttpException('Backend returned status ${response.statusCode}');
    }
    await for (final line in response.stream.toStringStream().transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map && decoded['content'] != null) {
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
    await for (final chunk in generateResponseAsync(message)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  @override
  Future<void> close() async {
    _systemPrompt = null;
  }
}

class SimulatedGemmaBridge implements IGemmaBridge {
  String? _currentSystemPrompt;
  bool _isInstalled = false;
  bool _isChatActive = false;

  @override
  Future<bool> isModelInstalled() async => _isInstalled;

  @override
  Future<void> setModelPath(String path) async {
    _isInstalled = true;
  }

  @override
  Future<void> createModel({required bool isInstructionTuned, int maxTokens = 2048}) async {}

  @override
  Future<void> createChatSession({String? systemPrompt}) async {
    _currentSystemPrompt = systemPrompt;
    _isChatActive = true;
  }

  @override
  Stream<String> generateResponseAsync(String message) async* {
    if (!_isChatActive) {
      throw StateError('Chat session is not active');
    }
    final fullReply = ContextPromptBuilder.generateSimulatedResponse(query: message, systemPrompt: _currentSystemPrompt ?? '');
    final words = fullReply.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 15));
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }

  @override
  Future<String> generateResponse(String message) async {
    if (!_isChatActive) {
      throw StateError('Chat session is not active');
    }
    return ContextPromptBuilder.generateSimulatedResponse(query: message, systemPrompt: _currentSystemPrompt ?? '');
  }

  @override
  Future<void> close() async {
    _isChatActive = false;
  }
}

class EdgeAiInferenceService {
  final ModelDownloadService downloadService;
  final IGemmaBridge _bridge;
  final Future<int> Function()? customRamProvider;
  static const int requiredFreeRamBytes = 1400 * 1024 * 1024;
  bool _isModelLoaded = false;
  bool _isChatActive = false;
  String? _currentSystemPrompt;

  EdgeAiInferenceService({
    required this.downloadService,
    IGemmaBridge? bridge,
    this.customRamProvider,
  }) : _bridge = bridge ?? BackendSseBridge();

  bool get isModelLoaded => _isModelLoaded;
  bool get isChatActive => _isChatActive;
  String? get currentSystemPrompt => _currentSystemPrompt;

  Future<int> getAvailableRamBytes() async {
    if (customRamProvider != null) {
      return await customRamProvider!();
    }
    return 3 * 1024 * 1024 * 1024;
  }

  Future<bool> hasEnoughRam({int requiredBytes = requiredFreeRamBytes}) async {
    final available = await getAvailableRamBytes();
    return available >= requiredBytes;
  }

  Future<bool> initModel({String? customPath}) async {
    try {
      final hasRam = await hasEnoughRam();
      if (!hasRam) {
        _isModelLoaded = false;
        return false;
      }
      if (_bridge is BackendSseBridge) {
        _isModelLoaded = true;
        return true;
      }
      String? path = customPath;
      if (path == null) {
        final modelFile = await downloadService.getModelFile();
        if (modelFile.existsSync() && modelFile.lengthSync() > 0) {
          path = modelFile.path;
        }
      }
      if (path == null || !File(path).existsSync()) {
        return false;
      }
      await _bridge.setModelPath(path);
      await _bridge.createModel(isInstructionTuned: true, maxTokens: 2048);
      _isModelLoaded = true;
      return true;
    } catch (_) {
      _isModelLoaded = false;
      return false;
    }
  }

  Future<void> startChatSession({required String systemPrompt, double? lat, double? lon}) async {
    final hasRam = await hasEnoughRam();
    if (!hasRam) {
      throw StateError('Thiết bị không đủ RAM trống để khởi chạy mô hình AI (cần tối thiểu 1.4 GB).');
    }
    if (!_isModelLoaded) {
      final initialized = await initModel();
      if (!initialized) {
        throw StateError('Model is not installed or downloaded yet.');
      }
    }
    if (_bridge is BackendSseBridge) {
      _bridge.latitude = lat;
      _bridge.longitude = lon;
    }
    _currentSystemPrompt = systemPrompt;
    await _bridge.createChatSession(systemPrompt: systemPrompt);
    _isChatActive = true;
  }

  Stream<String> sendMessageStream(String userMessage) async* {
    if (!_isChatActive) {
      throw StateError('Please call startChatSession before sending messages.');
    }
    yield* _bridge.generateResponseAsync(userMessage);
  }

  Future<String> sendMessage(String userMessage) async {
    if (!_isChatActive) {
      throw StateError('Please call startChatSession before sending messages.');
    }
    return await _bridge.generateResponse(userMessage);
  }

  Future<void> resetChatSession({String? newSystemPrompt}) async {
    final prompt = newSystemPrompt ?? _currentSystemPrompt;
    await _bridge.createChatSession(systemPrompt: prompt);
    _currentSystemPrompt = prompt;
    _isChatActive = true;
  }

  Future<void> dispose() async {
    _isChatActive = false;
    _isModelLoaded = false;
    await _bridge.close();
  }
}
