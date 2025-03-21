import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  /// 화면 높이에 비례한 상단 여백 비율
  final double topPadding;

  const WelcomeHeader({super.key, this.topPadding = 0.0});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 필요 시 로고, 글자 크기도 화면 크기에 맞춰 동적으로 조정
    final imageSize = screenWidth * 0.2;
    final titleFontSize = screenWidth * 0.05;
    final subtitleFontSize = screenWidth * 0.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 여백 최소화
        SizedBox(height: MediaQuery.of(context).size.height * topPadding),
        Image.asset(
          'assets/images/logo-green.webp',
          width: imageSize,
          height: imageSize,
          alignment: Alignment.centerLeft,
        ),
        SizedBox(height: imageSize * 0.2),
        Text(
          '환영합니다!',
          style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
        ),
        Text(
          '편하고 쉽게 골프를 즐겨보세요.',
          style: TextStyle(fontSize: subtitleFontSize),
        ),
        SizedBox(height: imageSize * 0.3),
      ],
    );
  }
}
