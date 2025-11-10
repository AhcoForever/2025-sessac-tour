import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../camera/screens/photo_gallery_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
              ),
              child: Column(
                children: [
                  // 프로필 아이콘
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 사용자 정보
                  Text(
                    user?.displayName ?? user?.email ?? '사용자',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 메뉴 리스트
            _buildMenuSection(
              context,
              title: '여행 기록',
              items: [
                _MenuItem(
                  icon: Icons.photo_library,
                  iconColor: Colors.blue,
                  title: '나의 여행 보관함',
                  subtitle: '촬영한 인증샷 보기',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhotoGalleryPage(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.map,
                  iconColor: Colors.green,
                  title: '방문한 장소',
                  subtitle: '내가 다녀온 관광지',
                  onTap: () {
                    // TODO: 방문한 장소 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중입니다')),
                    );
                  },
                ),
              ],
            ),

            _buildMenuSection(
              context,
              title: '설정',
              items: [
                _MenuItem(
                  icon: Icons.psychology,
                  iconColor: Colors.blue,
                  title: 'AI 채팅 선호도',
                  subtitle: '활동 수준, 예산, 관심사 설정',
                  onTap: () {
                    context.push('/chat-profile-edit');
                  },
                ),
                _MenuItem(
                  icon: Icons.person,
                  iconColor: Colors.orange,
                  title: '프로필 수정',
                  subtitle: '이름, 사진 변경',
                  onTap: () {
                    // TODO: 프로필 수정 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중입니다')),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications,
                  iconColor: Colors.purple,
                  title: '알림 설정',
                  subtitle: '푸시 알림 관리',
                  onTap: () {
                    // TODO: 알림 설정 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중입니다')),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.info,
                  iconColor: Colors.teal,
                  title: '앱 정보',
                  subtitle: '버전 및 라이선스',
                  onTap: () {
                    // TODO: 앱 정보 페이지
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중입니다')),
                    );
                  },
                ),
              ],
            ),

            _buildMenuSection(
              context,
              title: '계정',
              items: [
                _MenuItem(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  title: '로그아웃',
                  subtitle: '계정에서 로그아웃',
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final isLast = item == items.last;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: Colors.grey[200],
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context); // 다이얼로그 닫기
                // TODO: 로그인 페이지로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그아웃되었습니다')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
