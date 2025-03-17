import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;

  const CommentItem({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundImage: AssetImage('assets/images/apple.webp'),
        radius: 10,
      ),
      title: Row(
        children: [
          Text(
            comment['author'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Text(comment['content']),
        ],
      ),
      subtitle: Text(comment['time']),
    );
  }
}
