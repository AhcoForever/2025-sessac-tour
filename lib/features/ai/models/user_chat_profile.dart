import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 AI 채팅 프로필 모델
/// 대화 내용을 요약하여 저장하는 모델
class UserChatProfile {
  // 사용자 선호도
  final List<String> favoriteCategories; // 선호 카테고리 (힐링, 문화, 활력 등)
  final List<String> visitedPlaces; // 방문했던 장소들
  final List<String> interests; // 관심사 (전시, 공연, 산책 등)

  // 최근 추천 이력 (최대 10개)
  final List<RecommendationHistory> recentRecommendations;

  // 사용자 프로필
  final String? lastCharacter; // 마지막 대화한 캐릭터
  final List<String> moodPatterns; // 감지된 기분 패턴
  final String? activityLevel; // 활동 수준 (낮음/중간/높음)
  final String? budgetPreference; // 예산 선호도 (무료/저렴/상관없음)

  // 메타데이터
  final int totalChats; // 총 대화 횟수
  final DateTime? lastChatDate; // 마지막 대화 날짜
  final DateTime createdAt; // 프로필 생성일

  UserChatProfile({
    this.favoriteCategories = const [],
    this.visitedPlaces = const [],
    this.interests = const [],
    this.recentRecommendations = const [],
    this.lastCharacter,
    this.moodPatterns = const [],
    this.activityLevel,
    this.budgetPreference,
    this.totalChats = 0,
    this.lastChatDate,
    required this.createdAt,
  });

  /// Firestore에서 UserChatProfile 객체 생성
  factory UserChatProfile.fromFirestore(Map<String, dynamic> data) {
    return UserChatProfile(
      favoriteCategories: List<String>.from(data['favoriteCategories'] ?? []),
      visitedPlaces: List<String>.from(data['visitedPlaces'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      recentRecommendations: (data['recentRecommendations'] as List?)
              ?.map((item) => RecommendationHistory.fromMap(item))
              .toList() ??
          [],
      lastCharacter: data['lastCharacter'],
      moodPatterns: List<String>.from(data['moodPatterns'] ?? []),
      activityLevel: data['activityLevel'],
      budgetPreference: data['budgetPreference'],
      totalChats: data['totalChats'] ?? 0,
      lastChatDate: (data['lastChatDate'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'favoriteCategories': favoriteCategories,
      'visitedPlaces': visitedPlaces,
      'interests': interests,
      'recentRecommendations':
          recentRecommendations.map((r) => r.toMap()).toList(),
      'lastCharacter': lastCharacter,
      'moodPatterns': moodPatterns,
      'activityLevel': activityLevel,
      'budgetPreference': budgetPreference,
      'totalChats': totalChats,
      'lastChatDate':
          lastChatDate != null ? Timestamp.fromDate(lastChatDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }

  /// 빈 프로필 생성
  factory UserChatProfile.empty() {
    return UserChatProfile(
      createdAt: DateTime.now(),
    );
  }

  /// 새로운 추천 추가 (최대 10개 유지)
  UserChatProfile addRecommendation(RecommendationHistory recommendation) {
    final newRecommendations = [
      recommendation,
      ...recentRecommendations,
    ].take(10).toList();

    return copyWith(recentRecommendations: newRecommendations);
  }

  /// 방문 장소 추가 (중복 제거, 최대 30개)
  UserChatProfile addVisitedPlace(String place) {
    if (visitedPlaces.contains(place)) {
      return this;
    }
    final newPlaces = [...visitedPlaces, place].take(30).toList();
    return copyWith(visitedPlaces: newPlaces);
  }

  /// 관심사 추가 (중복 제거, 최대 20개)
  UserChatProfile addInterest(String interest) {
    if (interests.contains(interest)) {
      return this;
    }
    final newInterests = [...interests, interest].take(20).toList();
    return copyWith(interests: newInterests);
  }

  /// 선호 카테고리 추가 (중복 제거)
  UserChatProfile addFavoriteCategory(String category) {
    if (favoriteCategories.contains(category)) {
      return this;
    }
    return copyWith(favoriteCategories: [...favoriteCategories, category]);
  }

  /// 기분 패턴 추가 (최대 10개)
  UserChatProfile addMoodPattern(String pattern) {
    if (moodPatterns.contains(pattern)) {
      return this;
    }
    final newPatterns = [...moodPatterns, pattern].take(10).toList();
    return copyWith(moodPatterns: newPatterns);
  }

  /// 대화 횟수 증가
  UserChatProfile incrementChatCount() {
    return copyWith(
      totalChats: totalChats + 1,
      lastChatDate: DateTime.now(),
    );
  }

  /// copyWith 메서드
  UserChatProfile copyWith({
    List<String>? favoriteCategories,
    List<String>? visitedPlaces,
    List<String>? interests,
    List<RecommendationHistory>? recentRecommendations,
    String? lastCharacter,
    List<String>? moodPatterns,
    String? activityLevel,
    String? budgetPreference,
    int? totalChats,
    DateTime? lastChatDate,
    DateTime? createdAt,
  }) {
    return UserChatProfile(
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      visitedPlaces: visitedPlaces ?? this.visitedPlaces,
      interests: interests ?? this.interests,
      recentRecommendations:
          recentRecommendations ?? this.recentRecommendations,
      lastCharacter: lastCharacter ?? this.lastCharacter,
      moodPatterns: moodPatterns ?? this.moodPatterns,
      activityLevel: activityLevel ?? this.activityLevel,
      budgetPreference: budgetPreference ?? this.budgetPreference,
      totalChats: totalChats ?? this.totalChats,
      lastChatDate: lastChatDate ?? this.lastChatDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 추천 이력 모델
class RecommendationHistory {
  final String title; // 추천 제목
  final String category; // 카테고리 (힐링형/활력형/문화형)
  final String? description; // 설명
  final DateTime timestamp; // 추천 시간

  RecommendationHistory({
    required this.title,
    required this.category,
    this.description,
    required this.timestamp,
  });

  factory RecommendationHistory.fromMap(Map<String, dynamic> map) {
    return RecommendationHistory(
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      description: map['description'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
