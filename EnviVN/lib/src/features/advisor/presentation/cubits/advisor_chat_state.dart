import 'package:equatable/equatable.dart';

class ChatMessageItem extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessageItem({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessageItem copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessageItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [id, text, isUser, timestamp, isStreaming];
}

class AdvisorChatState extends Equatable {
  static const List<String> defaultSuggestedQuestions = [
    'Thời tiết và chất lượng không khí này có thích hợp chạy bộ ngoài trời không?',
    'Chỉ số bụi mịn hiện tại có ảnh hưởng gì đến trẻ nhỏ và người già không?',
    'Với lượng mưa hiện tại, khu vực này có nguy cơ ngập úng không?',
    'Tôi cần chuẩn bị trang phục và biện pháp bảo vệ gì khi ra ngoài bây giờ?',
  ];

  final bool isAiEnabled;
  final List<ChatMessageItem> messages;
  final bool isStreaming;
  final String? errorMessage;
  final List<String> suggestedQuestions;

  const AdvisorChatState({
    this.isAiEnabled = false,
    this.messages = const [],
    this.isStreaming = false,
    this.errorMessage,
    this.suggestedQuestions = defaultSuggestedQuestions,
  });

  AdvisorChatState copyWith({
    bool? isAiEnabled,
    List<ChatMessageItem>? messages,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
    List<String>? suggestedQuestions,
  }) {
    return AdvisorChatState(
      isAiEnabled: isAiEnabled ?? this.isAiEnabled,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
    );
  }

  @override
  List<Object?> get props => [
    isAiEnabled,
    messages,
    isStreaming,
    errorMessage,
    suggestedQuestions,
  ];
}
