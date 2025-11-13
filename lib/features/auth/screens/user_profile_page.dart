import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../camera/models/photo_memory.dart';
import '../../camera/services/photo_memory_service.dart';
import '../../camera/screens/photo_detail_page.dart';
import '../../ai/models/user_chat_profile.dart';
import '../../ai/services/chat_profile_service.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/stat_item_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/stat_card_widget.dart';
import '../widgets/photo_card_widget.dart';
import '../widgets/recommendation_card_widget.dart';

/// 사용자 프로필 페이지 (TabBar)
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '마이 프로필',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: '프로필'),
            Tab(icon: Icon(Icons.photo_library), text: '여행 보관함'),
            Tab(icon: Icon(Icons.favorite), text: '추천 루틴'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProfileEditTab(),
          _PhotoGalleryTab(),
          _RoutineTab(),
        ],
      ),
    );
  }
}

/// 1. 프로필 편집 탭
class _ProfileEditTab extends StatefulWidget {
  const _ProfileEditTab();

  @override
  State<_ProfileEditTab> createState() => _ProfileEditTabState();
}

class _ProfileEditTabState extends State<_ProfileEditTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isUpdating = false;
  String? _displayName;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// 사용자 프로필 로드
  void _loadUserProfile() {
    final user = _auth.currentUser;
    setState(() {
      _displayName = user?.displayName ?? user?.email?.split('@')[0];
      _photoURL = user?.photoURL;
    });
  }

  /// 프로필 사진 변경
  Future<void> _changeProfilePhoto() async {
    try {
      // 이미지 선택
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUpdating = true);

      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인된 사용자가 없습니다');

      // Firebase Storage에 업로드
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      await storageRef.putFile(File(image.path));
      final photoURL = await storageRef.getDownloadURL();

      // Firebase Auth 프로필 업데이트
      await user.updatePhotoURL(photoURL);

      // Firestore 사용자 문서 업데이트
      await _firestore.collection('users').doc(user.uid).set({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _photoURL = photoURL;
        _isUpdating = false;
      });

      if (mounted) {
        UiHelpers.showSuccessSnackBar(
            context, '✅ 프로필 사진이 변경되었습니다');
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        UiHelpers.showErrorSnackBar(context, '❌ 오류: $e');
      }
    }
  }

  /// 닉네임 변경
  Future<void> _changeDisplayName() async {
    final newName = await UiHelpers.showTextInputDialog(
      context: context,
      title: '닉네임 변경',
      label: '새 닉네임',
      initialValue: _displayName,
      maxLength: 20,
      confirmText: '변경',
    );

    if (newName == null || newName.isEmpty) return;

    try {
      setState(() => _isUpdating = true);

      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인된 사용자가 없습니다');

      // Firebase Auth 프로필 업데이트
      await user.updateDisplayName(newName);

      // Firestore 사용자 문서 업데이트
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _displayName = newName;
        _isUpdating = false;
      });

      if (mounted) {
        UiHelpers.showSuccessSnackBar(context, '✅ 닉네임이 변경되었습니다');
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        UiHelpers.showErrorSnackBar(context, '❌ 오류: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 프로필 사진
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _photoURL != null ? NetworkImage(_photoURL!) : null,
                  child: _photoURL == null
                      ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                      : null,
                ),
              ),
              if (_isUpdating)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _isUpdating ? null : _changeProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 닉네임
          Text(
            _displayName ?? '사용자',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 32),

          // 프로필 편집 카드
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: Colors.blue[700]),
                  ),
                  title: const Text('닉네임 변경'),
                  subtitle: Text(_displayName ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isUpdating ? null : _changeDisplayName,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo, color: Colors.green[700]),
                  ),
                  title: const Text('프로필 사진 변경'),
                  subtitle: const Text('갤러리에서 선택'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isUpdating ? null : _changeProfilePhoto,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. 여행 보관함 탭
class _PhotoGalleryTab extends StatefulWidget {
  const _PhotoGalleryTab();

  @override
  State<_PhotoGalleryTab> createState() => _PhotoGalleryTabState();
}

class _PhotoGalleryTabState extends State<_PhotoGalleryTab>
    with AutomaticKeepAliveClientMixin {
  final PhotoMemoryService _photoMemoryService = PhotoMemoryService();
  List<PhotoMemory> _photoMemories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPhotoMemories();
  }

  /// 사진 목록 불러오기
  Future<void> _loadPhotoMemories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final memories = await _photoMemoryService.getUserPhotoMemories();
      setState(() {
        _photoMemories = memories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 사진 삭제
  Future<void> _deletePhoto(PhotoMemory memory) async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: '사진 삭제',
      content: '${memory.destinationName}의 인증샷을\n삭제하시겠습니까?',
      confirmText: '삭제',
      confirmColor: Colors.red[700],
    );

    if (confirmed != true) return;

    final success = await _photoMemoryService.deletePhotoMemory(
      memory.id,
      memory.photoUrl,
    );

    if (mounted) {
      if (success) {
        UiHelpers.showSuccessSnackBar(context, '사진이 삭제되었습니다.');
        _loadPhotoMemories();
      } else {
        UiHelpers.showErrorSnackBar(context, '사진 삭제에 실패했습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const LoadingWidget(message: '사진을 불러오는 중...');
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: _errorMessage!,
        action: ElevatedButton(
          onPressed: _loadPhotoMemories,
          child: const Text('다시 시도'),
        ),
      );
    }

    if (_photoMemories.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.photo_library,
        title: '아직 촬영한 인증샷이 없어요',
        subtitle: '관광지에 도착해서 인증샷을 남겨보세요!',
      );
    }

    return Column(
      children: [
        // 통계 카드
        StatCardWidget(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[500]!],
          ),
          children: [
            StatItemWidget(
              icon: Icons.photo_camera,
              label: '총 인증샷',
              value: '${_photoMemories.length}',
            ),
            StatItemWidget(
              icon: Icons.location_on,
              label: '방문한 곳',
              value:
                  '${_photoMemories.map((m) => m.destinationId).toSet().length}',
            ),
          ],
        ),

        // 사진 그리드
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _photoMemories.length,
            itemBuilder: (context, index) {
              final memory = _photoMemories[index];
              return PhotoCardWidget(
                memory: memory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoDetailPage(
                        memory: memory,
                        onDelete: () => _deletePhoto(memory),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 3. 추천 루틴 탭
class _RoutineTab extends StatefulWidget {
  const _RoutineTab();

  @override
  State<_RoutineTab> createState() => _RoutineTabState();
}

class _RoutineTabState extends State<_RoutineTab>
    with AutomaticKeepAliveClientMixin {
  final ChatProfileService _profileService = ChatProfileService();
  UserChatProfile? _profile;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getChatProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      // 프로필 로드 실패 시 로그만 남기고 계속 진행
      if (mounted) {
        debugPrint('❌ 프로필 로드 실패: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const LoadingWidget(message: '추천 루틴을 불러오는 중...');
    }

    if (_profile == null || _profile!.recentRecommendations.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.favorite_border,
        title: '아직 추천받은 루틴이 없어요',
        subtitle: 'AI 채팅에서 장소 추천을 받아보세요!',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 통계 카드
        StatCardWidget(
          margin: EdgeInsets.zero,
          gradient: LinearGradient(
            colors: [Colors.purple[700]!, Colors.purple[500]!],
          ),
          children: [
            StatItemWidget(
              icon: Icons.recommend,
              label: '총 추천',
              value: '${_profile!.recentRecommendations.length}',
            ),
            StatItemWidget(
              icon: Icons.category,
              label: '선호 카테고리',
              value: '${_profile!.favoriteCategories.length}',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 추천 목록
        const Text(
          '최근 추천받은 장소',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ...(_profile!.recentRecommendations.map((rec) {
          return RecommendationCardWidget(recommendation: rec);
        })),
      ],
    );
  }
}
