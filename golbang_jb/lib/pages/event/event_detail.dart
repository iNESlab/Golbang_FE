import 'package:flutter/material.dart';
import 'package:golbang/pages/game/score_card_page.dart';
import '../../models/event.dart';
import '../../models/participant.dart';

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
                  'assets/images/golf_icon.png', // Example event image
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
                      '${event.startDateTime.toLocal().toIso8601String().split('T').first} • ${event.endDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')} ~ ${event.endDateTime.add(Duration(hours: 2)).hour}:${event.startDateTime.minute.toString().padLeft(2, '0')}', // Event time range
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
            // 참석자 수를 표시합니다
            Text(
              '참여 인원: ${event.participants.length}명',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // 참석 상태별 참석자 목록을 표시합니다
            _buildParticipantList('수락 및 회식', event.participants, 'PARTY'),
            _buildParticipantList('수락', event.participants, 'ACCEPT'),
            _buildParticipantList('거절', event.participants, 'DENY'),
            _buildParticipantList('대기', event.participants, 'PENDING'),
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

  // 각 status_type에 맞는 참석자 목록을 출력하는 위젯
  Widget _buildParticipantList(String title, List<Participant> participants, String statusType) {
    final filteredParticipants = participants.where((p) => p.statusType == statusType).toList();
    final count = filteredParticipants.length; // 해당 statusType의 참가자 수 계산

    if (count == 0) {
      return SizedBox(); // 해당 statusType에 참가자가 없을 경우 빈 공간 반환
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ($count):', // 제목에 참가자 수를 괄호 안에 표시
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        ...filteredParticipants.map((participant) {
          final member = participant.member;
          final isSameGroup = participant.groupType == event.participants.firstWhere((p) => p.participantId == event.myParticipantId).groupType;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // 각 Row의 아래에 10픽셀 간격 추가
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundImage: member?.profileImage != null
                      ? NetworkImage(member!.profileImage!)
                      : AssetImage('assets/images/user_default.png') as ImageProvider,
                ),
                SizedBox(width: 10),
                Container(
                  decoration: isSameGroup
                      ? BoxDecoration(
                    color: Colors.yellow.withOpacity(0.5), // 형광펜 효과를 위한 배경색
                    borderRadius: BorderRadius.circular(5),
                  )
                      : null,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    member != null
                        ? member.name
                        : 'Unknown', // 만약 member 정보가 없으면 'Unknown' 출력
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }
}
