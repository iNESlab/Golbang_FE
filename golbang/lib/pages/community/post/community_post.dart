import 'package:flutter/material.dart';

class CommunityPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const CommunityPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(post['profileImage'])),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(post['time'], style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (post['image'] != null)
          Image.asset(post['image']),
        const SizedBox(height: 10),
        Text(post['content']),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.thumb_up, size: 16),
            const SizedBox(width: 4),
            Text('${post['likes']}'),
          ],
        ),
      ],
    );
  }
}
