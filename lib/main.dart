import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sessactour/firebase_options.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'sessac tour',
      debugShowCheckedModeBanner: false,

      // FlexColorScheme 테마 적용
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // GoRouter 설정
      routerConfig: appRouter,
    );
  }
}
