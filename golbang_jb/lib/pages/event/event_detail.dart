import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as xx;
import 'package:flutter/material.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/utils/reponsive_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:golbang/pages/event/event_result.dart';
import '../../models/event.dart';
import '../../models/participant.dart';
import '../../models/responseDTO/GolfClubResponseDTO.dart';
import '../../provider/event/event_state_notifier_provider.dart';
import '../../provider/event/game_in_progress_provider.dart';
import '../../provider/screen_riverpod.dart';
import '../../repoisitory/secure_storage.dart';
import '../../utils/email.dart';
import '../../utils/excelFile.dart';
import '../../widgets/common/circular_default_person_icon.dart';
import '../game/score_card_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart'; // 공유 라이브러리 추가
import 'package:collection/collection.dart'; // mapIndexed 위해 필요


import 'event_update1.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;
  const EventDetailPage({super.key, required this.event});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final Map<int, bool> _isExpandedMap = {};
  LatLng? _selectedLocation;
  int? _myGroup;
  late Timer _timer;
  late DateTime currentTime; // 현재 시간을 저장할 변수
  late DateTime _startDateTime;
  late DateTime _endDateTime;

  GolfClubResponseDTO? _golfClubDetails;
  List<dynamic> participants = [];
  Map<String, dynamic>? teamAScores;
  Map<String, dynamic>? teamBScores;
  bool isLoading = true;
  late final _myParticipantId;
  late final _myStatus;

  late double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
  late double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
  late Orientation orientation = MediaQuery.of(context).orientation;
  late double fontSizeXLarge = ResponsiveUtils.getXLargeFontSize(screenWidth, orientation);
  late double fontSizeLarge = ResponsiveUtils.getLargeFontSize(screenWidth, orientation); // 너비의 4%를 폰트 크기로 사용
  late double fontSizeMedium = ResponsiveUtils.getMediumFontSize(screenWidth, orientation);
  late double fontSizeSmall = ResponsiveUtils.getSmallFontSize(screenWidth, orientation); // 너비의 3%를 폰트 크기로 사용
  late double appBarIconSize = ResponsiveUtils.getAppBarIconSize(screenWidth, orientation);

  @override
  void initState() {
    super.initState();
    _startDateTime = widget.event.startDateTime;
    _endDateTime = widget.event.endDateTime;
    _myParticipantId = widget.event.myParticipantId;
    _myStatus = widget.event.participants.firstWhere(
            (p)=>p.participantId == _myParticipantId
    ).statusType;

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
      fetchGolfClubDetails();
      fetchScores();
    });

  }

  Future<void> fetchGolfClubDetails() async {
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);
    final response = await eventService.getGolfCourseDetails(golfClubId: widget.event.golfClub!.golfClubId);
    if (mounted) {
      setState(() {
        _golfClubDetails = response;
      });
    }
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
    String? filePath = await createScoreExcelFile(
      eventId: widget.event.eventId,
      participants: participants,
      teamAScores: teamAScores,
      teamBScores: teamBScores,
    );
    if (filePath != null){
      try {
        await sendEmail(
          body: '제목: ${widget.event.eventTitle}\n 날짜: ${widget.event.startDateTime.toIso8601String().split('T').first}\n 장소: ${widget.event.site}',
          subject: '${widget.event.club!.name}_${widget.event.startDateTime.toIso8601String().split('T').first}_${widget.event.eventTitle}',
          recipients: [], // 받을 사람의 이메일 주소
          attachmentPaths: [filePath], // 첨부할 파일 경로
        );
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


  Icon _getStatusIcon(String statusType) {
    switch (statusType) {
      case 'PARTY':
        return const Icon(Icons.check_circle, color: Color(0xFF4D08BD));
      case 'ACCEPT':
        return const Icon(Icons.check_circle, color: Color(0xFF08BDBD));
      case 'DENY':
        return const Icon(Icons.cancel, color: Color(0xFFF21B3F));
      case 'PENDING':
        return const Icon(Icons.hourglass_top, color: Colors.grey);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  Widget _buildGroupPanels(List<Participant> participants) {
    final grouped = <int, List<Participant>>{};
    for (var p in participants) {
      grouped.putIfAbsent(p.groupType, () => []).add(p);
    }

    final groupKeys = grouped.keys.toList()..sort();

    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        final groupKey = groupKeys[index];
        setState(() {
          _isExpandedMap[groupKey] = !(_isExpandedMap[groupKey] ?? false);
        });
      },
      children: groupKeys.mapIndexed((index, group) {
        final groupMembers = grouped[group]!;

        return ExpansionPanel(
          isExpanded: _isExpandedMap[group] ?? false,
          canTapOnHeader: true,
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Text('$group조 (${groupMembers.length}명)', style: TextStyle(fontSize: fontSizeLarge)),
            );
          },
          body: Column(
            children: groupMembers.map((p) {
              final icon = _getStatusIcon(p.statusType);
              final member = p.member;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: (member?.profileImage != null && member!.profileImage.startsWith('https'))
                      ? NetworkImage(member.profileImage)
                      : null,
                  child: (member?.profileImage == null || member!.profileImage.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(member?.name ?? 'Unknown', style: TextStyle(fontSize: fontSizeMedium)),
                trailing: _getStatusIcon(p.statusType),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
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
    final screenSize = ref.read(screenSizeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle, style: TextStyle(fontSize: fontSizeLarge),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: appBarIconSize),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            //TODO: 레디스에서 읽는걸로 서버 변경시, 제거
            icon: Icon(Icons.attach_email_rounded, size: appBarIconSize),
            onPressed: () {
              // 게임 진행 중인지 확인
              final bool isGameInProgress = ref.read(
                gameInProgressProvider.select((map) => map[widget.event.eventId] ?? false),
              );

              if (isGameInProgress) {
                // 게임이 진행 중일 경우 경고 다이얼로그 표시
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('경고'),
                    content: const Text('게임 진행 중인 경우 데이터가 15분마다 동기화되어, 현재 점수와 일치하지 않을 수 있습니다. 계속 추출하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                        },
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          exportAndSendEmail(); // 이메일 내보내기 실행
                        },
                        child: const Text('추출'),
                      ),
                    ],
                  ),
                );
              } else {
                // 게임이 진행 중이 아닐 경우 바로 실행
                exportAndSendEmail();
              }
            },
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
              if(currentTime.isBefore(_startDateTime.add(const Duration(minutes: 30))))
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('수정'),
                ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제', style: TextStyle(fontSize: fontSizeMedium),),
              ),
              PopupMenuItem<String>(
                value: 'share', // 공유 버튼 추가
                child: Text('공유', style: TextStyle(fontSize: fontSizeMedium),),
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
                  CircleAvatar(
                    radius: screenSize.width * 0.1, // 반응형 아바타 크기
                    backgroundImage: widget.event.club!.image.startsWith('https')
                        ? NetworkImage(widget.event.club!.image)
                        : AssetImage(widget.event.club!.image) as ImageProvider,
                    backgroundColor: Colors.transparent, // 배경을 투명색으로 설정
                  ),
                  SizedBox(width: screenSize.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.eventTitle,
                          style: TextStyle(fontSize: fontSizeXLarge, fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,),
                        ),
                        Text(
                          '${_startDateTime.toIso8601String().split('T').first} • ${_startDateTime.hour}:${_startDateTime.minute.toString().padLeft(2, '0')} ~ ${_endDateTime.hour}:${_endDateTime.minute.toString().padLeft(2, '0')}${_startDateTime.toIso8601String().split('T').first !=
                              _endDateTime.toIso8601String().split('T').first
                              ? ' (${_endDateTime.toIso8601String().split('T').first})'
                              : ''}',
                          style: TextStyle(fontSize: fontSizeMedium, overflow: TextOverflow.ellipsis),
                        ),

                        Text(
                          '장소: ${widget.event.site}',
                          style: TextStyle(fontSize: fontSizeMedium),
                        ),
                        Text(
                          '게임모드: ${widget.event.displayGameMode}',
                          style: TextStyle(fontSize: fontSizeMedium),
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
                style: TextStyle(fontSize: fontSizeLarge),
              ),
              const SizedBox(height: 10),
              // 나의 조 표시
              Row(
                children: [
                  Text(
                    '나의 조: ',
                    style: TextStyle(fontSize: fontSizeLarge),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$_myGroup',
                      style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 토글 가능한 참석 상태별 리스트
              _buildGroupPanels(widget.event.participants),

              // 골프장 위치 표시
              if (_selectedLocation != null) ...[
                const SizedBox(height: 16),
                Text(
                  "골프장 위치",
                  style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _golfClubDetails != null
                        ? Column(
                      children: _golfClubDetails!.courses.map((course) {
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
                                      course.golfCourseName,
                                      style: TextStyle(
                                        fontSize: fontSizeLarge,
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
                                      style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      "코스 Par: ${course.par}",
                                      style: TextStyle(fontSize: fontSizeMedium, color: Colors.grey[700]),
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
                                    children: course.tees.isEmpty
                                        ? []
                                        : List.generate(course.holes, (index) {
                                      final holeNumber = index + 1;
                                      final par = course.tees[0].holePars[index];
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
                        : Text(
                      "코스 정보가 없습니다.",
                      style: TextStyle(color: Colors.redAccent, fontSize: fontSizeMedium),
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

  Widget? _buildBottomButtons() {

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
        child: Text('결과 조회', style: TextStyle(fontSize: fontSizeLarge)),
      );
    }
    else if (currentTime.isAfter(_startDateTime)) {
      bool isButtonActivate = _myStatus == 'ACCEPT' || _myStatus == 'PARTY';
      if (isButtonActivate){
        // 1) gameInProgressProvider에서 현재 이벤트ID에 대한 진행 여부 가져오기
        final bool isGameInProgress = ref.watch(
          gameInProgressProvider.select((map) => map[widget.event.eventId] ?? false),
        );
        return ElevatedButton(
          onPressed: () {
            // 아직 게임 중이 아니라면 게임시작
            if (!isGameInProgress) {
              ref.read(gameInProgressProvider.notifier).startGame(
                  widget.event.eventId);
            }
            // 스코어카드 페이지로 이동
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
          child: Text(isGameInProgress ? "게임 진행 중" : "게임 시작", style: TextStyle(fontSize: fontSizeLarge)),
        );
      }
      return null;
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
            style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.transparent,
                    child: (member?.profileImage != null && member!.profileImage.isNotEmpty)
                        ? (member.profileImage.startsWith('https')
                        ? ClipOval(
                      child: Image.network(
                        member.profileImage,
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return const CircularIcon(containerSize: 40.0);
                        },
                      ),
                    )
                        : (member.profileImage.startsWith('file://')
                        ? ClipOval(
                      child: Image.file(
                        File(member.profileImage.replaceFirst('file://', '')),
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return const CircularIcon(containerSize: 40.0);
                        },
                      ),
                    )
                        : const CircularIcon(containerSize: 40.0)))
                        : const CircularIcon(containerSize: 40.0),
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
                      style: TextStyle(fontSize: fontSizeMedium),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      isExpanded: _isExpandedMap[index] ?? false,
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
  final String par;

  DiagonalTextPainter({required this.holeNumber, required this.par});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    const textStyle = TextStyle(color: Colors.black, fontSize: 12);
    final holeTextSpan = TextSpan(text: "$holeNumber홀", style: textStyle);
    final parTextSpan = TextSpan(text: par, style: textStyle);

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