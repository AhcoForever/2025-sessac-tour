import '../models/recommendation.dart';
import '../services/chat_profile_service.dart';

/// 채팅 프로필 관리를 담당하는 클래스
class ChatProfileManager {
  final ChatProfileService _chatProfileService = ChatProfileService();

  /// 채팅 프로필 업데이트
  Future<void> updateProfile({
    String? characterId,
    List<Recommendation>? recommendations,
  }) async {
    try {
      // 1. 대화 횟수 증가
      await _chatProfileService.incrementChatCount();

      // 2. 캐릭터 정보 저장
      if (characterId != null) {
        await _chatProfileService.updateCharacter(characterId);
      }

      // 3. 추천이 있으면 저장
      if (recommendations != null && recommendations.isNotEmpty) {
        for (final rec in recommendations) {
          await _chatProfileService.addRecommendation(
            title: rec.title,
            category: rec.category,
            description: rec.description,
          );

          // 카테고리를 선호 카테고리로 추가
          await _chatProfileService.addFavoriteCategory(rec.category);
        }
      }

      print('✅ 채팅 프로필 업데이트 완료');
    } catch (e) {
      print('❌ 채팅 프로필 업데이트 실패: $e');
      // 프로필 저장 실패는 사용자 경험에 영향을 주지 않도록 무시
    }
  }
}
