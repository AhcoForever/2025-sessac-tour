import 'package:go_router/go_router.dart';
import 'package:sessactour/core/landing_page.dart';
import 'package:sessactour/features/ai/screens/ai_chat_page.dart';
import 'package:sessactour/features/ai/screens/character_select_page.dart';
import 'package:sessactour/features/ai/screens/chat_profile_edit_page.dart';
import 'package:sessactour/features/ai/screens/routine_recommendation_page.dart';
import 'package:sessactour/features/auth/screens/account_deletion_page.dart';
import 'package:sessactour/features/auth/screens/forgot_password_page.dart';
import 'package:sessactour/features/auth/screens/login_page.dart';
import 'package:sessactour/features/auth/screens/logout_page.dart';
import 'package:sessactour/features/auth/screens/signup_page.dart';
import 'package:sessactour/features/auth/screens/user_profile_page.dart';
import 'package:sessactour/features/camera/screens/photo_capture_page.dart';
import 'package:sessactour/features/map/screens/map_page.dart';
import 'package:sessactour/features/public_data/screens/content_detail_page.dart';
import 'package:sessactour/features/public_data/screens/content_list_page.dart';
import 'package:sessactour/features/public_data/screens/cultural_events_page.dart';
import 'package:sessactour/features/setting/screens/profile_page.dart';

import '../features/auth/services/auth_service.dart';
import '../features/error/screens/error_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  // 경로가 매치되지 않을 때 표시할 화면
  errorBuilder: (context, state) {
    return ErrorScreen(message: state.error.toString());
  },

  routes: [
    GoRoute(
      path: '/',
      name: 'landing',
      builder: (context, state) =>
          //UserProfilePage()
      // ChatProfileEditPage()
          //MapPage(),
      //ContentListPage()
      //CulturalEventsPage()
      LandingPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => SignupPage(),
    ),
    GoRoute(
      path: '/forgotpassword',
      name: 'forgotpassword',
      builder: (context, state) => ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/apitest',
      name: 'apitest',
      builder: (context, state) => CulturalEventsPage(),
    ),
    GoRoute(
      path: '/character-select',
      name: 'character-select',
      builder: (context, state) => CharacterSelectPage(),
    ),
    GoRoute(
      path: '/ai-chat',
      name: 'ai-chat',
      builder: (context, state) => AiChatPage(),
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) {
        // extra로 전달된 파라미터 받기
        final extra = state.extra as Map<String, dynamic>?;
        return MapPage(routeParams: extra);
      },
    ),

    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => ProfilePage(),
    ),
    GoRoute(
      path: '/logout',
      name: 'logout',
      builder: (context, state) => ProfilePage(),
    ),
    // PhotoCapturePage는 MapPage에서 Navigator.push로만 접근
    // (required 매개변수들이 필요하므로 라우터로 직접 접근 불가)
    // GoRoute(
    //   path: '/photo-capture',
    //   name: 'photo-capture',
    //   builder: (context, state) => PhotoCapturePage(),
    // ),
    GoRoute(
      path: '/account-deletion',
      name: 'account-deletion',
      builder: (context, state) => AccountDeletionPage(),
    ),
    GoRoute(
      path: '/routine-recommendation',
      name: 'routine-recommendation',
      builder: (context, state) => RoutineRecommendationPage(),
    ),
    GoRoute(
      path: '/chat-profile-edit',
      name: 'chat-profile-edit',
      builder: (context, state) => ChatProfileEditPage(),
    ),
    GoRoute(
      path: '/user-profile',
      name: 'user-profile',
      builder: (context, state) => UserProfilePage(),
    ),

    // GoRoute(
    //   path: '/map',
    //   name: 'map',
    //   builder: (context, state) => MapPage(),
    // ),
  ],
  // 전역 리다이렉트 (모든 라우트에 적용)
  redirect: (context, state) {
    //final isLoggedIn = AuthService.isLoggedIn();
    final isGOingToLogin = state.matchedLocation == '/login';

    //로그인되지 않았고 로그인 페이지로 가는 중이 아니면 로그인 페이지로 리다이렉트
    // if (!isLoggedIn && !isGoingToLogin) {
    //   return 'login?redirect=${state.matchedLocation}';
    // }

    // 이미 로그인되었고 로그인 페이지로 가려고 한다면 홈으로 리다이렉트
    //   if(isLoggedIn && isGOingToLogin){
    //     return '/';
    //   }
    //
    //   // 리다이렉트 없음
    //   return null;
    //
  },
);
