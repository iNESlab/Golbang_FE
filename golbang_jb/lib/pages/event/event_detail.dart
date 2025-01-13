import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as xx;
import 'package:flutter/material.dart';
import 'package:golbang/services/event_service.dart';
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
import 'package:path_provider/path_provider.dart';  // path_provider 패키지 임포트
import 'package:flutter_email_sender/flutter_email_sender.dart'; // 이메일 전송 패키지 추가

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;
  const EventDetailPage({super.key, required this.event});

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

  List<dynamic> participants = [];
  Map<String, dynamic>? teamAScores;
  Map<String, dynamic>? teamBScores;
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _startDateTime = widget.event.startDateTime;
    _endDateTime = widget.event.endDateTime;

    _selectedLocation = _parseLocation(widget.event.location);
    _myGroup = widget.event.memberGroup; // initState에서 초기화
    currentTime = DateTime.now(); // 초기화 시점의 현재 시간
    // 타이머를 통해 1초마다 상태 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchScores();
    });
  }
  Future<void> fetchScores() async {
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);
    try {
      final response = await eventService.getScoreData(widget.event.eventId);

      if (response != null) {
        setState(() {
          participants = response['participants'];
          teamAScores = response['team_a_scores'];
          teamBScores = response['team_b_scores'];
          isLoading = false;
        });
      } else {
        log('Failed to load scores: response is null');
      }
    } catch (error) {
      log('Error fetching scores: $error');
    }
  }
  Future<void> exportAndSendEmail() async {
    // 엑셀 파일 생성
    var excel = xx.Excel.createExcel();
    var sheet = excel['Sheet1'];

    // 열 제목 설정 (기본은 행 형태로)
    List<String> columnTitles = [
      '팀',
      '참가자',
      '전반전',
      '후반전',
      '전체 스코어',
      '핸디캡 스코어',
      'hole 1',
      'hole 2',
      'hole 3',
      'hole 4',
      'hole 5',
      'hole 6',
      'hole 7',
      'hole 8',
      'hole 9',
      'hole 10',
      'hole 11',
      'hole 12',
      'hole 13',
      'hole 14',
      'hole 15',
      'hole 16',
      'hole 17',
      'hole 18'
    ];

    // 팀 데이터와 참가자별 점수를 병합하여 정렬
    List<Map<String, dynamic>> sortedParticipants = [
      if (teamAScores != null)
        {
          'team': 'Team A',
          'participant_name': '-',
          'front_nine_score': teamAScores?['front_nine_score'],
          'back_nine_score': teamAScores?['back_nine_score'],
          'total_score': teamAScores?['total_score'],
          'handicap_score': '-',
          'scorecard': List.filled(18, '-'),
        },
      if (teamBScores != null)
        {
          'team': 'Team B',
          'participant_name': '-',
          'front_nine_score': teamBScores?['front_nine_score'],
          'back_nine_score': teamBScores?['back_nine_score'],
          'total_score': teamBScores?['total_score'],
          'handicap_score': '-',
          'scorecard': List.filled(18, '-'),
        },
      ...participants.map((participant) => {
        'team': participant['team'], // 팀 정보 추가
        'participant_name': participant['participant_name'],
        'front_nine_score': participant['front_nine_score'],
        'back_nine_score': participant['back_nine_score'],
        'total_score': participant['total_score'],
        'handicap_score': participant['handicap_score'],
        'scorecard': participant['scorecard'],
      }),
    ];

    // 팀 기준으로 정렬
    sortedParticipants.sort((a, b) => a['team'].compareTo(b['team']));

    // 데이터를 행 기준으로 변환
    List<List<dynamic>> rows = [
      columnTitles, // 제목
      ...sortedParticipants.map((participant) {
        return [
          participant['team'],
          participant['participant_name'],
          participant['front_nine_score'],
          participant['back_nine_score'],
          participant['total_score'],
          participant['handicap_score'],
          ...List.generate(18, (i) => participant['scorecard'].length > i ? participant['scorecard'][i] : '-'),
        ];
      }),
    ];

    // Transpose 적용 (행과 열 교환)
    List<List<dynamic>> transposedData = List.generate(
      rows[0].length,
          (colIndex) => rows.map((row) => row[colIndex]).toList(),
    );

    // 엑셀에 데이터 쓰기
    for (var row in transposedData) {
      sheet.appendRow(row);
    }

    // 외부 저장소 경로 가져오기
    Directory? directory;

    if (Platform.isAndroid) {
      // Android: 외부 저장소 경로 가져오기
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      // iOS: 문서 디렉토리 가져오기
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      String filePath = '${directory.path}/event_scores_${widget.event.eventId}.xlsx';
      File file = File(filePath);

      // 파일 쓰기
      await file.writeAsBytes(excel.encode()!);

      // 이메일 전송
      final Email email = Email(
        body: '제목: ${widget.event.eventTitle}\n 날짜: ${widget.event.startDateTime.toIso8601String().split('T').first}\n 장소: ${widget.event.site}',
        subject: '${widget.event.club!.name}_${widget.event.startDateTime.toIso8601String().split('T').first}_${widget.event.eventTitle}',
        recipients: [], // 받을 사람의 이메일 주소
        attachmentPaths: [filePath], // 첨부할 파일 경로
        isHTML: false,
      );

      try {
        await FlutterEmailSender.send(email);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 전송 실패: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 경로를 찾을 수 없습니다.')),
      );
    }
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.email), // 엑셀 저장 아이콘 추가
            onPressed: exportAndSendEmail,
          ),
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
                  Image(
                    image: widget.event.club!.image.startsWith('https')
                        ? NetworkImage(widget.event.club!.image) as ImageProvider
                        : AssetImage('assets/images/golf_icon.png') as ImageProvider,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        widget.event.eventTitle,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,),
                      ),
                      Text(
                        '${_startDateTime.toIso8601String().split('T').first} • ${_startDateTime.hour}:${_startDateTime.minute.toString().padLeft(2, '0')} ~ ${_endDateTime.hour}:${_endDateTime.minute.toString().padLeft(2, '0')}${_startDateTime.toIso8601String().split('T').first !=
                                _endDateTime.toIso8601String().split('T').first
                                ? ' (${_endDateTime.toIso8601String().split('T').first})'
                                : ''}',
                        style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
                      ),

                      Text(
                        '장소: ${widget.event.site}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '게임모드: ${widget.event.displayGameMode}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$_myGroup',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 토글 가능한 참석 상태별 리스트
              ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: const EdgeInsets.all(0),
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isExpandedList[index] = !_isExpandedList[index];
                  });
                },
                children: [
                  _buildParticipantPanel('참석 및 회식', widget.event.participants, 'PARTY', const Color(0xFF4D08BD).withOpacity(0.3), 0),
                  _buildParticipantPanel('참석', widget.event.participants, 'ACCEPT', const Color(0xFF08BDBD).withOpacity(0.3), 1),
                  _buildParticipantPanel('거절', widget.event.participants, 'DENY', const Color(0xFFF21B3F).withOpacity(0.3), 2),
                  _buildParticipantPanel('대기', widget.event.participants, 'PENDING', const Color(0xFF7E7E7E).withOpacity(0.3), 3),
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
                    const Text(
                      "코스 정보",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    widget.event.golfClub != null
                        ? Column(
                      children: widget.event.golfClub!.courses.map((course) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.golf_course, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      course.courseName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                                const SizedBox(height: 10),
                                const Divider(),
                                const SizedBox(height: 10),

                                // 홀 번호, Par 및 Handicap 테이블 형식 표시
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(course.holes, (index) {
                                      final holeNumber = index + 1;
                                      final par = course.holePars[index];
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
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
                        : const Text(
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
        const SnackBar(content: Text('이벤트 삭제에 실패했습니다. 모임 관리자만 삭제할 수 있습니다.')),
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

    const textStyle = TextStyle(color: Colors.black, fontSize: 12);
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

    holePainter.paint(canvas, const Offset(5, 5));
    parPainter.paint(canvas, Offset(size.width - parPainter.width - 5, size.height - parPainter.height - 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}