import 'package:flutter/material.dart';
import 'package:golbang/pages/game/score_card_page.dart';
import '../../models/event.dart';
import '../../models/participant.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;
  EventDetailPage({required this.event});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  List<bool> _isExpandedList = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 사용자의 groupType을 가져옵니다
    final myGroupType = widget.event.participants
        .firstWhere((p) => p.participantId == widget.event.myParticipantId)
        .groupType;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
<<<<<<< HEAD
<<<<<<< HEAD
      body: SingleChildScrollView( // 스크롤 가능하도록 설정
=======
      body: SingleChildScrollView(
>>>>>>> d8ab64b (design(event): 각 StatusType(수락 및 회식, 수락, 거절, 대기)을 토글 가능한 형태로 변경하여, 섹션을 눌렀을 때만 해당 참가자들이 보이도록 설정)
        child: Padding(
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
                        widget.event.eventTitle,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.event.startDateTime.toLocal().toIso8601String().split('T').first} • ${widget.event.endDateTime.hour}:${widget.event.startDateTime.minute.toString().padLeft(2, '0')} ~ ${widget.event.endDateTime.add(Duration(hours: 2)).hour}:${widget.event.startDateTime.minute.toString().padLeft(2, '0')}', // Event time range
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '장소: ${widget.event.location}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '게임모드: ${widget.event.gameMode}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 참석자 수를 표시합니다
              Text(
                '참여 인원: ${widget.event.participants.length}명',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              // 나의 조 표시
              Row(
                children: [
                  Text(
                    '나의 조: ',
                    style: TextStyle(fontSize: 16),
=======
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
            SizedBox(height: 10),
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
>>>>>>> 1d2879a (design(event): 이벤트 상세 조회 페이지에 참여자의 status_type과 이름 정보 리스트 추가)
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5), // 형광펜 효과를 위한 배경색
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$myGroupType',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // 토글 가능한 참석 상태별 리스트
              ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: EdgeInsets.all(0),
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isExpandedList[index] = !_isExpandedList[index];
                  });
                },
                children: [
                  _buildParticipantPanel('수락 및 회식', widget.event.participants, 'PARTY', Colors.purple.withOpacity(0.3), 0),
                  _buildParticipantPanel('수락', widget.event.participants, 'ACCEPT', Colors.blue.withOpacity(0.3), 1),
                  _buildParticipantPanel('거절', widget.event.participants, 'DENY', Colors.red.withOpacity(0.3), 2),
                  _buildParticipantPanel('대기', widget.event.participants, 'PENDING', Colors.grey.withOpacity(0.3), 3),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
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
    );
  }

<<<<<<< HEAD
  // 각 status_type에 맞는 참석자 목록을 출력하는 위젯
<<<<<<< HEAD
  Widget _buildParticipantList(String title, List<Participant> participants, String statusType, Color backgroundColor) {
=======
  // 각 status_type에 맞는 참가자 목록을 출력하는 ExpansionPanel
  ExpansionPanel _buildParticipantPanel(String title, List<Participant> participants, String statusType, Color backgroundColor, int index) {
>>>>>>> d8ab64b (design(event): 각 StatusType(수락 및 회식, 수락, 거절, 대기)을 토글 가능한 형태로 변경하여, 섹션을 눌렀을 때만 해당 참가자들이 보이도록 설정)
    final filteredParticipants = participants.where((p) => p.statusType == statusType).toList();
    final count = filteredParticipants.length; // 해당 statusType의 참가자 수 계산

    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor, // 상태별 배경색 설정
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(10),
          child: Text(
            '$title ($count):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor, // 상태별 배경색 설정
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredParticipants.map((participant) {
            final member = participant.member;
            final isSameGroup = participant.groupType == widget.event.participants.firstWhere((p) => p.participantId == widget.event.myParticipantId).groupType;

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
        ),
      ),
<<<<<<< HEAD
=======
  Widget _buildParticipantList(String title, List<Participant> participants, String statusType) {
    final filteredParticipants = participants.where((p) => p.statusType == statusType).toList();

    if (filteredParticipants.isEmpty) {
      return SizedBox(); // 해당 statusType에 참가자가 없을 경우 빈 공간 반환
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        ...filteredParticipants.map((participant) => Text(
          participant.member != null
              ? '- ${participant.member!.name}' // 참가자의 이름을 표시
              : '- ${participant.participantId}', // 참가자의 이름이 없을 경우 ID 표시
          style: TextStyle(fontSize: 14),
        )),
        SizedBox(height: 10),
      ],
>>>>>>> 1d2879a (design(event): 이벤트 상세 조회 페이지에 참여자의 status_type과 이름 정보 리스트 추가)
=======
      isExpanded: _isExpandedList[index],
      canTapOnHeader: true,
>>>>>>> d8ab64b (design(event): 각 StatusType(수락 및 회식, 수락, 거절, 대기)을 토글 가능한 형태로 변경하여, 섹션을 눌렀을 때만 해당 참가자들이 보이도록 설정)
    );
  }
}
