import 'package:flutter/material.dart';
import 'home_page.dart'; // 메인 화면 위젯 import
import 'dart:ui';

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
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0), // 흐릿함은 제거
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(<double>[
                  0.8, 0, 0, 0, 0, // Red 감소
                  0, 0.8, 0, 0, 0, // Green 감소
                  0, 0, 0.8, 0, 0, // Blue 감소
                  0, 0, 0, 1, 0, // Alpha 유지
                ]),
                child: Image.asset('assets/images/logo.png'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'GOLBANG',
              style: TextStyle(
                fontSize: 48,
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