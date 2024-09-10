import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:golbang/pages/event/event_result.dart';
import '../../models/event.dart';
import '../../models/participant.dart';
<<<<<<< HEAD
import '../game/score_card_page.dart';
=======
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';
import 'event_create1.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
>>>>>>> 90a90bc (feat(event): 이벤트 수정, 삭제 버튼 클릭시 발생하는 이벤트 함수 구현)

import 'event_update.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;

  EventDetailPage({required this.event});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  List<bool> _isExpandedList = [false, false, false, false];
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = _parseLocation(widget.event.location);
  }

  LatLng? _parseLocation(String? location) {
    if (location == null) {
      return null;
    }

    try {
      if (location.startsWith('LatLng')) {
        final coords = location
            .substring(7, location.length - 1) // "LatLng("와 ")" 제거
            .split(',')
            .map((e) => double.parse(e.trim())) // 공백 제거 후 숫자로 변환
            .toList();
        return LatLng(coords[0], coords[1]);
      } else {
        return null; // LatLng 형식이 아니면 null 반환
      }
    } catch (e) {
      return null; // 파싱 실패 시 null 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    final myGroupType = widget.event.memberGroup;

    // 더미 데이터
    final courseName = "더미 코스 이름";
    final hole = "18홀";
    final par = "72";
    final courseType = "더미 코스 타입";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  _editEvent();
                  break;
                case 'delete':
                  _deleteEvent();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('수정'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Row(
                children: [
                  Image.asset(
                    'assets/images/golf_icon.png',
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
                        '${widget.event.startDateTime.toLocal().toIso8601String().split('T').first} • ${widget.event.endDateTime.hour}:${widget.event.startDateTime.minute.toString().padLeft(2, '0')} ~ ${widget.event.endDateTime.add(Duration(hours: 2)).hour}:${widget.event.startDateTime.minute.toString().padLeft(2, '0')}',
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
              // 참석자 수를 표시
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
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5),
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
                  _buildParticipantPanel('참석 및 회식', widget.event.participants, 'PARTY', Color(0xFF4D08BD).withOpacity(0.3), 0),
                  _buildParticipantPanel('참석', widget.event.participants, 'ACCEPT', Color(0xFF08BDBD).withOpacity(0.3), 1),
                  _buildParticipantPanel('거절', widget.event.participants, 'DENY', Color(0xFFF21B3F).withOpacity(0.3), 2),
                  _buildParticipantPanel('대기', widget.event.participants, 'PENDING', Color(0xFF7E7E7E).withOpacity(0.3), 3),
                ],
              ),

              // 골프장 위치 표시
              if (_selectedLocation != null) ...[
                SizedBox(height: 16),
                Text(
                  "골프장 위치",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 14.0,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('selected-location'),
                        position: _selectedLocation!,
                      ),
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "코스 정보",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text("코스 이름: $courseName"),
                Text("홀: $hole"),
                Text("Par: $par"),
                Text("코스 타입: $courseType"),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoreCardPage(event: widget.event),
                    ),
                  );
                },
                child: Text('게임 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventResultPage(eventId: widget.event.eventId),
                    ),
                  );
                },
                child: Text('결과 조회'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
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
        child: _buildBottomButtons(),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final DateTime currentDate = DateTime.now();
    final DateTime eventDate = widget.event.startDateTime;

    if (currentDate.isBefore(eventDate)) {
      // 현재 날짜가 이벤트 날짜보다 이전인 경우 "게임 시작" 버튼만 표시
      return ElevatedButton(
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
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } else {
      // 현재 날짜가 이벤트 날짜보다 이후인 경우 "결과 조회" 버튼만 표시
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventResultPage(eventId: widget.event.eventId),
            ),
          );
        },
        child: Text('결과 조회'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }
  }

  ExpansionPanel _buildParticipantPanel(String title, List<Participant> participants, String statusType, Color backgroundColor, int index) {
    final filteredParticipants = participants.where((p) => p.statusType == statusType).toList();
    final count = filteredParticipants.length;

    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
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
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredParticipants.map((participant) {
            final member = participant.member;
            final isSameGroup = participant.groupType == widget.event.participants.firstWhere((p) => p.participantId == widget.event.myParticipantId).groupType;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
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
                      color: Colors.yellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    )
                        : null,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      member != null ? member.name : 'Unknown',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      isExpanded: _isExpandedList[index],
      canTapOnHeader: true,
    );
  }

  void _editEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventEditPage(eventId: widget.event.eventId),
      ),
    ).then((updatedEvent) {
      if (updatedEvent != null) {
        // 수정된 이벤트 데이터를 받아서 API 호출
        _updateEvent(updatedEvent);
      }
    });
  }

  void _updateEvent(Event updatedEvent) async {
    // ref.watch를 이용하여 storage 인스턴스를 얻고 이를 EventService에 전달
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);

    final eventData = {
      "event_title": updatedEvent.eventTitle,
      "location": updatedEvent.location,
      "start_date_time": updatedEvent.startDateTime.toIso8601String(),
      "end_date_time": updatedEvent.endDateTime.toIso8601String(),
      "game_mode": updatedEvent.gameMode.toString(),
      // 필요한 다른 필드들 추가
    };

    final success = await eventService.updateEvent(widget.event.eventId, eventData);

    if (success) {
      // 성공 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('성공적으로 수정되었습니다')),
      );
      // 이벤트 상세 페이지로 돌아오기
      Navigator.of(context).pop(); // 생성 페이지에서 상세 페이지로 돌아오기
    } else {
      // 실패 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 수정에 실패했습니다.')),
      );
    }
  }

  void _deleteEvent() async {
    // ref.watch를 이용하여 storage 인스턴스를 얻고 이를 EventService에 전달
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);

    final success = await eventService.deleteEvent(widget.event.eventId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('성공적으로 삭제되었습니다')),
      );
      Navigator.of(context).pop(); // 삭제 후 페이지를 나가기
    } else if(success == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('관리자가 아닙니다. 관리자만 삭제할 수 있습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 삭제에 실패했습니다.')),
      );
    }
  }
}
