import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    // 3초후 로그인 페이지도 이동됨.
    Future.delayed(const Duration(seconds: 3),() {
      if (mounted) {
        context.goNamed('login');
      }
    } );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이미지 미리 로드 (전환 시 깜빡임 방지)
    precacheImage(const AssetImage('assets/images/landing_image.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 시스템 UI 영역까지 확장
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 전체 채우기
          Image.asset(
            'assets/images/landing_image.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}
