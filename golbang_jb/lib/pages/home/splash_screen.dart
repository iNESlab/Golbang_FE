import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_page.dart'; // 메인 화면 위젯 import
import 'package:get/get.dart';  // GetX 사용

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainScreen();
  }

  void _navigateToMainScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.go('/home'); // ✅ go_router로 전환!
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // 배경색을 흰색으로 설정
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_white.webp',
               width: 200,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/text-logo-white.webp',  // 텍스트 로고 이미지
              width: 300, // 이미지 크기 조정
              fit: BoxFit.contain,

            ),
          ],
        ),
      ),
    );
  }
}