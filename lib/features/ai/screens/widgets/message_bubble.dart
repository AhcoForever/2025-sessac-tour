import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/chracter.dart';
import 'recommendation_card.dart';

/// 메시지 버블 위젯
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Character? character;

  const MessageBubble({
    super.key,
    required this.message,
    this.character,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 메시지 버블
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  backgroundColor: character?.themeColor ??
                      Theme.of(context).colorScheme.primary,
                  child: character != null
                      ? ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              character!.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.smart_toy,
                                    color: Colors.white);
                              },
                            ),
                          ),
                        )
                      : const Icon(Icons.smart_toy, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? Colors.white70
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ],
          ),

          // 추천 카드 (assistant 메시지에만 표시)
          if (!isUser && message.recommendations != null) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.only(left: 48), // 아바타 크기만큼 들여쓰기
                  child: SizedBox(
                    width: constraints.maxWidth - 48, // 왼쪽 패딩을 제외한 나머지 너비
                    child: Column(
                      children: message.recommendations!
                          .map((recommendation) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: RecommendationCard(
                                  recommendation: recommendation,
                                  onTap: () {
                                    // TODO: 상세 페이지로 이동
                                    print('카드 클릭: ${recommendation.title}');
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
