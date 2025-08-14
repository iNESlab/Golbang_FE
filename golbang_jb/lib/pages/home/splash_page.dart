import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// 메인 화면 위젯 import

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToMainScreen();
  }

  // Navigate to the main screen after a delay
  Future<void> _navigateToMainScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    // 이전 스택을 제거하면서 /home으로 이동
    if (mounted) {
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 흰색으로 설정
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo-green.webp',
              height: 100, // 이미지 크기 조정 (필요에 따라 수정)
              width: 100,  // 이미지 크기 조정 (필요에 따라 수정)
            ),
            const SizedBox(height: 16),
            const Text(
              'GOLBANG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
