import 'package:flutter/material.dart';

class CircularIcon extends StatelessWidget {
  final double containerSize;
  final double? iconSize;
  final Color backgroundColor;
  final Color iconColor;

  const CircularIcon({
    Key? key,
    this.containerSize = 60.0, // 기본값
    this.iconSize,            // 비율 계산 시 기본값은 null
    this.backgroundColor = const Color(0xFFE0E0E0), // 기본값 (light grey)
    this.iconColor = Colors.grey, // 기본값
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calculatedIconSize = iconSize ?? containerSize * 0.5; // 기본적으로 45% 크기로 설정

    return ClipOval(
      child: Container(
        color: backgroundColor,
        width: containerSize,
        height: containerSize,
        child: Icon(
          Icons.person,
          size: calculatedIconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
