import 'package:flutter/material.dart';

/// 차단 다이얼로그 위젯
/// 사용자를 차단할지 확인하는 다이얼로그입니다.
class BlockDialog extends StatelessWidget {
  final String userName;
  final double fontSizeLarge;
  final double fontSizeMedium;
  final double fontSizeSmall;
  final VoidCallback onBlock;

  const BlockDialog({
    super.key,
    required this.userName,
    required this.fontSizeLarge,
    required this.fontSizeMedium,
    required this.fontSizeSmall,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('사용자 차단', style: TextStyle(fontSize: fontSizeLarge)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${userName}님을 차단하시겠습니까?',
               style: TextStyle(fontSize: fontSizeMedium)),
          const SizedBox(height: 8),
          Text('차단된 사용자의 메시지는 더 이상 보이지 않습니다.',
               style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey[600])),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소', style: TextStyle(fontSize: fontSizeMedium)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onBlock();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('차단하기', style: TextStyle(fontSize: fontSizeMedium, color: Colors.white)),
        ),
      ],
    );
  }
}

/// 차단 다이얼로그를 표시하는 헬퍼 함수
void showBlockDialog({
  required BuildContext context,
  required String userName,
  required double fontSizeLarge,
  required double fontSizeMedium,
  required double fontSizeSmall,
  required VoidCallback onBlock,
}) {
  showDialog(
    context: context,
    builder: (context) => BlockDialog(
      userName: userName,
      fontSizeLarge: fontSizeLarge,
      fontSizeMedium: fontSizeMedium,
      fontSizeSmall: fontSizeSmall,
      onBlock: onBlock,
    ),
  );
}
