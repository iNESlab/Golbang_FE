import 'package:flutter/material.dart';
import 'home_page.dart'; // 메인 화면 위젯 import

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePage(), // HomePage 위젯으로 변경
      ),
    );
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
              'assets/images/logo-green.png',
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
