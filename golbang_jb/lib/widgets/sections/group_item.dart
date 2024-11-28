import 'package:flutter/material.dart';

class GroupItem extends StatelessWidget {
  final String image;
  final String label;
  final bool isAdmin; // 관리자인지 여부를 받는 필드 추가

  const GroupItem({
    super.key,
    required this.image,
    required this.label,
    required this.isAdmin, // isAdmin 필드 필수로 설정
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Column의 크기를 최소화하여 간격 최적화
      children: [
        // 이미지 표시
        SizedBox(
          width: 90,
          height: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // 이미지 둥글게
            child: Image.asset(image, fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: 5), // 이미지와 텍스트 사이 간격
        // 그룹 이름 표시
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        // 관리자인 경우 "관리자" 텍스트와 아이콘 표시
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.green[700], size: 16), // 초록색 관리자 아이콘
                SizedBox(width: 4),
                Text(
                  '관리자',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
