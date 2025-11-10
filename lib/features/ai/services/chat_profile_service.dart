import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_chat_profile.dart';

/// AI 채팅 프로필 관리 서비스
class ChatProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자의 채팅 프로필 참조
  DocumentReference<Map<String, dynamic>>? get _currentUserProfileRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('chat').doc('profile');
  }

  /// 채팅 프로필 가져오기
  Future<UserChatProfile?> getChatProfile() async {
    try {
      final profileRef = _currentUserProfileRef;
      if (profileRef == null) {
        print('⚠️ 로그인된 사용자가 없습니다.');
        return null;
      }

      final doc = await profileRef.get();

      if (doc.exists && doc.data() != null) {
        return UserChatProfile.fromFirestore(doc.data()!);
      } else {
        // 프로필이 없으면 빈 프로필 반환
        return UserChatProfile.empty();
      }
    } catch (e) {
      print('❌ 채팅 프로필 로드 실패: $e');
      return null;
    }
  }

  /// 채팅 프로필 저장
  Future<void> saveChatProfile(UserChatProfile profile) async {
    try {
      final profileRef = _currentUserProfileRef;
      if (profileRef == null) {
        print('⚠️ 로그인된 사용자가 없습니다.');
        return;
      }

      await profileRef.set(profile.toFirestore(), SetOptions(merge: true));
      print('✅ 채팅 프로필 저장 완료');
    } catch (e) {
      print('❌ 채팅 프로필 저장 실패: $e');
    }
  }

  /// 추천 기록 추가
  Future<void> addRecommendation({
    required String title,
    required String category,
    String? description,
  }) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final recommendation = RecommendationHistory(
        title: title,
        category: category,
        description: description,
        timestamp: DateTime.now(),
      );

      final updatedProfile = profile.addRecommendation(recommendation);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 추천 기록 추가 실패: $e');
    }
  }

  /// 방문 장소 추가
  Future<void> addVisitedPlace(String place) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.addVisitedPlace(place);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 방문 장소 추가 실패: $e');
    }
  }

  /// 관심사 추가
  Future<void> addInterest(String interest) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.addInterest(interest);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 관심사 추가 실패: $e');
    }
  }

  /// 선호 카테고리 추가
  Future<void> addFavoriteCategory(String category) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.addFavoriteCategory(category);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 선호 카테고리 추가 실패: $e');
    }
  }

  /// 기분 패턴 추가
  Future<void> addMoodPattern(String pattern) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.addMoodPattern(pattern);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 기분 패턴 추가 실패: $e');
    }
  }

  /// 대화 횟수 증가
  Future<void> incrementChatCount() async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.incrementChatCount();
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 대화 횟수 증가 실패: $e');
    }
  }

  /// 캐릭터 업데이트
  Future<void> updateCharacter(String characterId) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.copyWith(lastCharacter: characterId);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 캐릭터 업데이트 실패: $e');
    }
  }

  /// 활동 수준 업데이트
  Future<void> updateActivityLevel(String level) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.copyWith(activityLevel: level);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 활동 수준 업데이트 실패: $e');
    }
  }

  /// 예산 선호도 업데이트
  Future<void> updateBudgetPreference(String preference) async {
    try {
      final profile = await getChatProfile();
      if (profile == null) return;

      final updatedProfile = profile.copyWith(budgetPreference: preference);
      await saveChatProfile(updatedProfile);
    } catch (e) {
      print('❌ 예산 선호도 업데이트 실패: $e');
    }
  }

  /// 채팅 프로필 스트림 (실시간 업데이트)
  Stream<UserChatProfile?> watchChatProfile() {
    final profileRef = _currentUserProfileRef;
    if (profileRef == null) {
      return Stream.value(null);
    }

    return profileRef.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserChatProfile.fromFirestore(doc.data()!);
      }
      return UserChatProfile.empty();
    });
  }

  /// 채팅 프로필 삭제
  Future<void> deleteChatProfile() async {
    try {
      final profileRef = _currentUserProfileRef;
      if (profileRef == null) {
        print('⚠️ 로그인된 사용자가 없습니다.');
        return;
      }

      await profileRef.delete();
      print('✅ 채팅 프로필 삭제 완료');
    } catch (e) {
      print('❌ 채팅 프로필 삭제 실패: $e');
    }
  }
}
