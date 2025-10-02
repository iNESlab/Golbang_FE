import 'package:flutter/material.dart';

/// 반응 표시 위젯
/// 메시지에 대한 반응(좋아요 등)을 표시하는 위젯입니다.
class Reactions extends StatelessWidget {
  final Map<String, int> reactions;
  final String messageId;
  final Function(String, String)? onAddReaction;

  const Reactions({
    super.key,
    required this.reactions,
    required this.messageId,
    this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((entry) {
          return GestureDetector(
            onTap: () => onAddReaction?.call(messageId, entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
