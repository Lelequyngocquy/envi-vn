/// Pure domain contract for Backend SSE AI advisor chat sessions.
abstract class IAiChatService {
  bool get isChatActive;
  Future<void> startChatSession({double? lat, double? lon});
  Stream<String> sendMessageStream(
    String userMessage, {
    List<Map<String, String>> history = const [],
  });
  Future<String> sendMessage(
    String userMessage, {
    List<Map<String, String>> history = const [],
  });
  Future<void> resetChatSession({double? lat, double? lon});
  Future<void> dispose();
}
