import 'package:flutter/material.dart';

/// 바텀시트 아이템 위젯
/// 바텀시트에서 사용할 메뉴 아이템 위젯입니다.
class BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final double fontSizeMedium;
  final VoidCallback onTap;

  const BottomSheetItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.fontSizeMedium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
