import 'package:flutter/material.dart';

class AnnouncementItem extends StatelessWidget {
  final String title;
  final String date;
  final String content;
  final String image;

  AnnouncementItem({
    required this.title,
    required this.date,
    required this.content,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(image, width: 50, height: 50),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 5),
                Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
