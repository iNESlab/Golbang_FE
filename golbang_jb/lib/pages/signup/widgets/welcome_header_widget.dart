import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final double topPadding; // 상단 여백을 위한 조정값

  const WelcomeHeader({super.key, this.topPadding = 0.3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * topPadding),
        // 로고 이미지
        Image.asset(
          'assets/images/logo-green.png',
          width: 100,
          height: 100,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),
        // 환영 메시지
        const Text(
          '환영합니다!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          '편하고 쉽게 골프를 즐겨보세요.',
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
