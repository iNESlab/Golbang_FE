import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:golbang/pages/event/event_result.dart';
import '../../models/event.dart';
import '../../models/participant.dart';
import '../../provider/event/event_state_notifier_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../game/score_card_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart'; // 공유 라이브러리 추가

import 'event_update1.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;
  EventDetailPage({required this.event});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final List<bool> _isExpandedList = [false, false, false, false];
  LatLng? _selectedLocation;
  int? _myGroup;
  late Timer _timer;
  late DateTime currentTime; // 현재 시간을 저장할 변수
  late DateTime _startDateTime;
  late DateTime _endDateTime;


  @override
  void initState() {
    super.initState();
    _startDateTime = widget.event.startDateTime;
    _endDateTime = widget.event.endDateTime;

    _selectedLocation = _parseLocation(widget.event.location);
    _myGroup = widget.event.memberGroup; // initState에서 초기화
    currentTime = DateTime.now(); // 초기화 시점의 현재 시간
    // 타이머를 통해 1초마다 상태 업데이트
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });

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
  void dispose() {
    _timer.cancel(); // 타이머 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // 더미 데이터
    const courseName = "더미 코스 이름";
    const hole = "18홀";
    const par = "72";
    const courseType = "더미 코스 타입";

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
                case 'share': // 공유 버튼 추가
                  _shareEvent();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if(currentTime.isBefore(_startDateTime))
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('수정'),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제'),
              ),
              const PopupMenuItem<String>(
                value: 'share', // 공유 버튼 추가
                child: Text('공유'),
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
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.eventTitle,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_startDateTime.toIso8601String().split('T').first} • '
                            '${_startDateTime.hour}:${_startDateTime.minute.toString().padLeft(2, '0')} ~ '
                            '${_endDateTime.hour}:${_endDateTime.minute.toString().padLeft(2, '0')}' +
                            (_startDateTime.toIso8601String().split('T').first !=
                                _endDateTime.toIso8601String().split('T').first
                                ? ' (${_endDateTime.toIso8601String().split('T').first})'
                                : ''),
                        style: const TextStyle(fontSize: 16),
                      ),

                      Text(
                        '장소: ${widget.event.site}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '게임모드: ${widget.event.gameMode}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 참석자 수를 표시
              Text(
                '참여 인원: ${widget.event.participants.length}명',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              // 나의 조 표시
              Row(
                children: [
                  const Text(
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
                      '$_myGroup',
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
                const SizedBox(height: 16),
                const Text(
                  "골프장 위치",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                        markerId: const MarkerId('selected-location'),
                        position: _selectedLocation!,
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // 코스 정보 표시
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "코스 정보",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    widget.event.golfClub != null
                        ? Column(
                      children: widget.event.golfClub!.courses.map((course) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.golf_course, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      course.courseName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "홀 수: ${course.holes}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      "코스 Par: ${course.par}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Divider(),
                                SizedBox(height: 10),

                                // 홀 번호, Par 및 Handicap 테이블 형식 표시
                                SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(course.holes, (index) {
                                      final holeNumber = index + 1;
                                      final par = course.holePars[index];
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                          border: Border.all(color: Colors.grey[300]!, width: 1),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CustomPaint(
                                            painter: DiagonalTextPainter(holeNumber: holeNumber, par: par),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : Text(
                      "코스 정보가 없습니다.",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBottomButtons(),
      ),
    );
  }

  Widget _buildBottomButtons() {

    if (currentTime.isAfter(_endDateTime)){
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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: const Text('결과 조회'),
      );
    }
    else if (currentTime.isAfter(widget.event.startDateTime)) {
      // 현재 날짜가 이벤트 날짜보다 이전인 경우 "게임 시작" 버튼만 표시
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScoreCardPage(event: widget.event),

            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: const Text('게임 시작'),
      );
    } else {
      return  ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: Text(_formatTimeDifference(_startDateTime)),
      );
    }
  }

  String _formatTimeDifference(DateTime targetDateTime) {
    final difference = targetDateTime.difference(currentTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 후 시작';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 후 시작';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 후 시작';
    } else {
      return '곧 시작';
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
          padding: const EdgeInsets.all(10),
          child: Text(
            '$title ($count):',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredParticipants.map((participant) {
            final member = participant.member;
            final isSameGroup = participant.groupType == _myGroup;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: member?.profileImage != null
                        ? NetworkImage(member!.profileImage!)
                        : const AssetImage('assets/images/user_default.png') as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: isSameGroup
                        ? BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    )
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      member != null ? member.name : 'Unknown',
                      style: const TextStyle(fontSize: 14),
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
        builder: (context) => EventsUpdate1(event: widget.event), // 이벤트 데이터 전달
      ),
    ).then((result) {
      if (result == true) {
        // 수정 후 페이지 나가기
        Navigator.of(context).pop(true);
      }
    });
  }

  void _shareEvent() {
    // Firebase Hosting 링크를 기반으로 이벤트 링크 생성
    final String eventLink =
        "https://golbang-test/?event_id=${widget.event.eventId}";

    Share.share(
      '이벤트를 확인해보세요!\n\n'
          '제목: ${widget.event.eventTitle}\n'
          '날짜: ${_startDateTime.toIso8601String().split('T').first}\n'
          '장소: ${widget.event.site}\n\n'
          '자세히 보기: $eventLink',
    );
  }


  void _deleteEvent() async {
    // ref.watch를 이용하여 storage 인스턴스를 얻고 이를 EventService에 전달
    // final storage = ref.watch(secureStorageProvider);
    // final eventService = EventService(storage);

    // final success = await eventService.deleteEvent(widget.event.eventId);

    final success = await ref.read(eventStateNotifierProvider.notifier).deleteEvent(widget.event.eventId);


    if (success) {
      // 이벤트 삭제 후 목록 새로고침
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성공적으로 삭제되었습니다')),
      );
      Navigator.of(context).pop(true); // 삭제 후 페이지를 나가기
    } else if(success == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관리자가 아닙니다. 관리자만 삭제할 수 있습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이벤트 삭제에 실패했습니다.')),
      );
    }
  }
}

// 대각선 구분선 및 텍스트 표시를 위한 CustomPainter
class DiagonalTextPainter extends CustomPainter {
  final int holeNumber;
  final int par;

  DiagonalTextPainter({required this.holeNumber, required this.par});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    final textStyle = TextStyle(color: Colors.black, fontSize: 12);
    final holeTextSpan = TextSpan(text: "$holeNumber홀", style: textStyle);
    final parTextSpan = TextSpan(text: "$par", style: textStyle);

    final holePainter = TextPainter(
      text: holeTextSpan,
      textDirection: TextDirection.ltr,
    );
    final parPainter = TextPainter(
      text: parTextSpan,
      textDirection: TextDirection.ltr,
    );

    holePainter.layout();
    parPainter.layout();

    holePainter.paint(canvas, Offset(5, 5));
    parPainter.paint(canvas, Offset(size.width - parPainter.width - 5, size.height - parPainter.height - 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}