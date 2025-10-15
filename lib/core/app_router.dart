import 'package:go_router/go_router.dart';
import 'package:sessactour/features/auth/screens/forgot_password_page.dart';
import 'package:sessactour/features/auth/screens/login_page.dart';
import 'package:sessactour/features/auth/screens/signup_page.dart';

import '../features/error/screens/error_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) {
    return ErrorScreen(message: state.error.toString());
  },
  routes: [
    GoRoute(
      path: '/',
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
  ],
);
