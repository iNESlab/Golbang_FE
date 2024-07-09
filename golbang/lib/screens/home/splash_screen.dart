import 'package:flutter/material.dart';
import 'home_screen.dart'; // 메인 화면 위젯 import

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainScreen();
  }

  _navigateToMainScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(), // MainScreen 위젯으로 변경
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
            Image.asset('assets/images/google.png'), // 로고 이미지 추가 (경로 수정 필요)
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
