import 'package:flutter/material.dart';
import 'package:golbang/pages/game/score_card_page.dart';
import '../../models/event.dart';
import '../../models/group.dart';

class EventDetailPage extends StatelessWidget {
  final Event event;

  EventDetailPage({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.eventTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            Row(
              children: [
                Image.asset(
                  'assets/images/apple.png', // Example event image
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.eventTitle,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${event.time.toLocal().toIso8601String().split('T').first} • ${event.time.hour}:${event.time.minute.toString().padLeft(2, '0')} ~ ${event.time.add(Duration(hours: 2)).hour}:${event.time.minute.toString().padLeft(2, '0')}', // Event time range
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '장소: ${event.location}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '게임모드: ${event.gameMode}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              '참여 인원: ${event.participants}명',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            // Dynamic members' list or any additional event details
            if (event.attendanceStatus == '참석') ...[
              Text(
                '참석자: ${event.group}', // Display group details or members
                style: TextStyle(fontSize: 16),
              ),
              // Add other dynamic content based on event properties
            ],
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoreCardPage(),
                    ),
                  );
                },

                child: Text('게임 시작'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 버튼의 배경색 설정
                  foregroundColor: Colors.white, // 텍스트 색을 흰색으로 설정
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
