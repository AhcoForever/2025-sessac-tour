import 'package:flutter/material.dart';
import '../models/user_chat_profile.dart';
import '../services/chat_profile_service.dart';

/// AI 채팅 프로필 편집 페이지
class ChatProfileEditPage extends StatefulWidget {
  const ChatProfileEditPage({super.key});

  @override
  State<ChatProfileEditPage> createState() => _ChatProfileEditPageState();
}

class _ChatProfileEditPageState extends State<ChatProfileEditPage> {
  final ChatProfileService _profileService = ChatProfileService();

  UserChatProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  // 편집 가능한 필드
  String? _activityLevel;
  String? _budgetPreference;
  Set<String> _selectedInterests = {};
  Set<String> _selectedCategories = {};

  // 선택 가능한 옵션들
  final List<String> _activityLevelOptions = ['낮음', '중간', '높음'];
  final List<String> _budgetOptions = ['무료', '저렴', '상관없음'];
  final List<String> _interestOptions = [
    '전시', '공연', '산책', '맛집', '쇼핑', '역사', '자연', '사진', '운동', '카페'
  ];
  final List<String> _categoryOptions = [
    '힐링형', '활력형', '문화형', '야경', '공원', '문화공간'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// 프로필 로드
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getChatProfile();

      setState(() {
        _profile = profile;
        _activityLevel = profile?.activityLevel;
        _budgetPreference = profile?.budgetPreference;
        _selectedInterests = Set.from(profile?.interests ?? []);
        _selectedCategories = Set.from(profile?.favoriteCategories ?? []);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 프로필 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 프로필 저장
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final updatedProfile = (_profile ?? UserChatProfile.empty()).copyWith(
        activityLevel: _activityLevel,
        budgetPreference: _budgetPreference,
        interests: _selectedInterests.toList(),
        favoriteCategories: _selectedCategories.toList(),
      );

      await _profileService.saveChatProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 프로필이 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ 프로필 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 채팅 프로필 설정'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 통계
                  _buildStatsCard(),
                  const SizedBox(height: 24),

                  // 활동 수준
                  _buildSectionTitle('활동 수준'),
                  const SizedBox(height: 8),
                  _buildActivityLevelSelector(),
                  const SizedBox(height: 24),

                  // 예산 선호도
                  _buildSectionTitle('예산 선호도'),
                  const SizedBox(height: 8),
                  _buildBudgetPreferenceSelector(),
                  const SizedBox(height: 24),

                  // 관심사
                  _buildSectionTitle('관심사'),
                  const SizedBox(height: 8),
                  _buildInterestsSelector(),
                  const SizedBox(height: 24),

                  // 선호 카테고리
                  _buildSectionTitle('선호 카테고리'),
                  const SizedBox(height: 8),
                  _buildCategoriesSelector(),
                  const SizedBox(height: 24),

                  // 추천 이력
                  if (_profile != null && _profile!.recentRecommendations.isNotEmpty) ...[
                    _buildSectionTitle('최근 추천 이력'),
                    const SizedBox(height: 8),
                    _buildRecommendationHistory(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  /// 프로필 통계 카드
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'AI 채팅 프로필',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '대화 횟수',
                '${_profile?.totalChats ?? 0}회',
                Icons.chat_bubble_outline,
              ),
              _buildStatItem(
                '추천 받음',
                '${_profile?.recentRecommendations.length ?? 0}개',
                Icons.recommend_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 활동 수준 선택
  Widget _buildActivityLevelSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _activityLevelOptions.map((level) {
          return RadioListTile<String>(
            title: Text(level),
            subtitle: Text(_getActivityLevelDescription(level)),
            value: level,
            groupValue: _activityLevel,
            onChanged: (value) {
              setState(() => _activityLevel = value);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 활동 수준 설명
  String _getActivityLevelDescription(String level) {
    switch (level) {
      case '낮음':
        return '느긋하고 편안한 활동을 선호합니다';
      case '중간':
        return '적당한 활동량을 선호합니다';
      case '높음':
        return '활발하고 에너지 넘치는 활동을 선호합니다';
      default:
        return '';
    }
  }

  /// 예산 선호도 선택
  Widget _buildBudgetPreferenceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _budgetOptions.map((budget) {
          return RadioListTile<String>(
            title: Text(budget),
            subtitle: Text(_getBudgetDescription(budget)),
            value: budget,
            groupValue: _budgetPreference,
            onChanged: (value) {
              setState(() => _budgetPreference = value);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 예산 선호도 설명
  String _getBudgetDescription(String budget) {
    switch (budget) {
      case '무료':
        return '무료로 즐길 수 있는 장소를 선호합니다';
      case '저렴':
        return '저렴한 비용으로 즐길 수 있는 곳을 선호합니다';
      case '상관없음':
        return '비용에 제약 없이 추천받고 싶습니다';
      default:
        return '';
    }
  }

  /// 관심사 선택
  Widget _buildInterestsSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _interestOptions.map((interest) {
          final isSelected = _selectedInterests.contains(interest);
          return FilterChip(
            label: Text(interest),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedInterests.add(interest);
                } else {
                  _selectedInterests.remove(interest);
                }
              });
            },
            backgroundColor: Colors.white,
            selectedColor: Colors.blue[100],
            checkmarkColor: Colors.blue[700],
          );
        }).toList(),
      ),
    );
  }

  /// 선호 카테고리 선택
  Widget _buildCategoriesSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categoryOptions.map((category) {
          final isSelected = _selectedCategories.contains(category);
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCategories.add(category);
                } else {
                  _selectedCategories.remove(category);
                }
              });
            },
            backgroundColor: Colors.white,
            selectedColor: Colors.green[100],
            checkmarkColor: Colors.green[700],
          );
        }).toList(),
      ),
    );
  }

  /// 추천 이력
  Widget _buildRecommendationHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _profile!.recentRecommendations.take(5).map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.place,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        rec.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
