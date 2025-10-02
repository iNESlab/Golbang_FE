import 'package:flutter/material.dart';
import 'package:golbang/models/chat_room.dart';

/// 차단된 메시지 플레이스홀더 위젯
/// 차단된 사용자의 메시지를 표시하는 독립적인 위젯입니다.
class BlockedMessagePlaceholder extends StatelessWidget {
  final ChatMessage message;
  final double fontSizeSmall;
  final double fontSizeMedium;
  final Function(ChatMessage)? onToggleBlockedMessage;

  const BlockedMessagePlaceholder({
    super.key,
    required this.message,
    required this.fontSizeSmall,
    required this.fontSizeMedium,
    this.onToggleBlockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '차단된 메시지입니다',
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onToggleBlockedMessage?.call(message),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '탭하여 보기',
                        style: TextStyle(
                          fontSize: fontSizeSmall - 2,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
