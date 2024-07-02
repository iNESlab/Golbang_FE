import 'package:flutter/material.dart';

class AnnouncementItem extends StatelessWidget {
  final String title;
  final String date;
  final String content;

  AnnouncementItem({required this.title, required this.date, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue),
              SizedBox(width: 5),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Spacer(),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          SizedBox(height: 5),
          Text(content, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
