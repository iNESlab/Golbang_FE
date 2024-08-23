import 'package:flutter/material.dart';

class GroupItem extends StatelessWidget {
  final String image;
  final String label;

  GroupItem({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, width: 100, height: 70),
          Text(
            label,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis, // 텍스트가 길면 "..." 표시
          ),
        ],
      ),
    );
  }
}
