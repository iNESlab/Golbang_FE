import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;

  const CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage('assets/images/apple.png'),
        radius: 10,
      ),
      title: Row(
        children: [
          Text(
            comment['author'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 5),
          Text(comment['content']),
        ],
      ),
      subtitle: Text(comment['time']),
    );
  }
}
