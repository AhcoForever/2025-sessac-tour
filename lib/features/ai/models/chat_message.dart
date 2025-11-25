import 'recommendation.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<Recommendation>? recommendations; // 추천 카드 리스트

  // ID 충돌 방지를 위한 카운터
  static int _idCounter = 0;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.recommendations,
  });

  /// 고유 ID 생성 (microsecond + counter로 충돌 방지)
  static String _generateUniqueId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: _generateUniqueId(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(
    String content, {
    List<Recommendation>? recommendations,
  }) {
    return ChatMessage(
      id: _generateUniqueId(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      recommendations: recommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
    };
  }
}
