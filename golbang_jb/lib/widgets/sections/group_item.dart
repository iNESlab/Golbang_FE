import 'package:flutter/material.dart';

class GroupItem extends StatelessWidget {
  final String image;
  final String label;
  final bool isAdmin;

  const GroupItem({
    super.key,
    required this.image,
    required this.label,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min, // Column 크기를 최소화
      crossAxisAlignment: CrossAxisAlignment.center, // 중앙 정렬
      children: [
        // 이미지 표시
        SizedBox(
          width: screenWidth / 5, // 화면 너비의 1/6 크기
          height: (screenWidth / 5)-4, // 화면 너비의 1/6 크기
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image.contains('https') // 문자열 검사
                ? Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ), // 네트워크 에러 처리
            )
                : Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ), // 로컬 파일 에러 처리
            ),
          ),
        ),
        const SizedBox(height: 8), // 이미지와 텍스트 사이 간격
        // 그룹 이름 표시
        Container(
          width: screenWidth / 5, // 텍스트 너비를 화면 너비의 1/5로 제한
          alignment: Alignment.center, // 텍스트 중앙 정렬
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1, // 텍스트 한 줄로 제한
            overflow: TextOverflow.ellipsis, // 긴 텍스트 생략 표시
          ),
        ),
        // 관리자인 경우 "관리자" 텍스트와 아이콘 표시
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.green[700], size: 16),
                const SizedBox(width: 4),
                Text(
                  '관리자',
                  style: TextStyle(
                    fontSize: 14,
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
