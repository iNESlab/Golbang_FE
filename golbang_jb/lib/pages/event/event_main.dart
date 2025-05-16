import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/event_create1.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:golbang/utils/reponsive_utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import '../../models/event.dart';
import '../../provider/club/club_state_provider.dart';
import '../../provider/event/game_in_progress_provider.dart';
import '../../provider/participant/participant_state_provider.dart';
import '../../utils/date_utils.dart';
import 'package:golbang/services/participant_service.dart';
import 'package:golbang/services/event_service.dart';
import '../game/score_card_page.dart';
import 'event_detail.dart';
import 'package:get/get.dart';

import 'event_result.dart';

class EventPage extends ConsumerStatefulWidget {
  const EventPage({super.key});

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends ConsumerState<EventPage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // late EventService _eventService;
  late ParticipantService _participantService;
  late Timer _timer;
  late DateTime currentTime; // 현재 시간을 저장할 변수

  late double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
  late double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
  late Orientation orientation = MediaQuery.of(context).orientation;
  late double fontSizeXLarge = ResponsiveUtils.getXLargeFontSize(screenWidth, orientation);
  late double fontSizeLarge = ResponsiveUtils.getLargeFontSize(screenWidth, orientation); // 너비의 4%를 폰트 크기로 사용
  late double fontSizeMedium = ResponsiveUtils.getMediumFontSize(screenWidth, orientation);
  late double fontSizeSmall = ResponsiveUtils.getSmallFontSize(screenWidth, orientation); // 너비의 3%를 폰트 크기로 사용
  late double appBarIconSize = ResponsiveUtils.getAppBarIconSize(screenWidth, orientation);

  final Map<DateTime, List<Event>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  Future<void> _checkAndNavigateToEventDetail() async {
    // Get.arguments에서 eventId 가져오기
    int? eventId = Get.arguments?['eventId'];

    if (eventId != -1) {
      final storage = ref.read(secureStorageProvider);
      final EventService eventService = EventService(storage);

      try {
        // 이벤트 상세 정보 가져오기
        final event = await eventService.getEventDetails(eventId!);
        if (event != null) {
          // UI 빌드 후 이벤트 상세 페이지로 이동
          Get.arguments?['eventId'] = -1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailPage(event: event),
              ),
            );
          });
        }
      } catch (e) {
        log('Error fetching event details: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getUpcomingEvents());
    currentTime = DateTime.now(); // 초기화 시점의 현재 시간

    // 타이머를 통해 1초마다 상태 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
    // 앱 시작 시 클럽 데이터를 강제로 로드
    final clubNotifier = ref.read(clubStateProvider.notifier);
    clubNotifier.fetchClubs();

    // eventId 확인 및 상세 페이지로 이동
    _checkAndNavigateToEventDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMostRecentEvent();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = ref.watch(secureStorageProvider);
    // _eventService = EventService(storage);
    _participantService = ParticipantService(storage);
    _loadEventsForMonth();

    // // 여기서 participantStateProvider의 상태를 listen해서, 상태가 변경되면 이벤트 목록을 다시 로드합니다.
    // ref.listen<ParticipantState>(participantStateProvider, (previous, next) {
    //   _loadEventsForMonth();
    // });
  }

  Future<void> _loadEventsForMonth() async {
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);
    String date = '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-01';

    try {
      List<Event> events = await eventService.getEventsForMonth(date: date);
      setState(() {
        _events.clear(); // 이전 데이터를 초기화
        for (var event in events) {
          DateTime eventDate = DateTime(
            event.startDateTime.year,
            event.startDateTime.month,
            event.startDateTime.day,
          );

          if (_events.containsKey(eventDate)) {
            _events[eventDate]!.add(event);
          } else {
            _events[eventDate] = [event];
          }
        }
        _selectedEvents.value = _getEventsForDay(_selectedDay!); // UI 새로고침
      });
    } catch (e) {
      log("Error loading events: $e");
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  List<Event> _getUpcomingEvents() {
    return _events.entries
        .where((entry) => entry.key.isAfter(currentTime) || isSameDay(entry.key, currentTime))
        .expand((entry) => entry.value)
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.endDateTime));
  }

  void _showMostRecentEvent() {
    if (_events.isEmpty) return;

    DateTime mostRecentDay = _events.keys
        .where((date) => date.isAfter(currentTime) || isSameDay(date, currentTime))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    _selectedDay = mostRecentDay;
    _focusedDay = mostRecentDay;
    _selectedEvents.value = _getEventsForDay(mostRecentDay);
    setState(() {});
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _timer.cancel(); // 타이머 해제
    super.dispose();
  }

  void _navigateToGameStartPage(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreCardPage(event: event), // GameStartPage 생성 필요
      ),
    );

    if (result == true) {
      await _loadEventsForMonth(); // 페이지 종료 후 이벤트 목록 새로고침
    }
  }

  void _navigateToResultPage(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventResultPage(eventId: event.eventId), // ResultPage 생성 필요
      ),
    );

    if (result == true) {
      await _loadEventsForMonth(); // 페이지 종료 후 이벤트 목록 새로고침
    }
  }



  @override
  Widget build(BuildContext context) {
    final clubState = ref.watch(clubStateProvider);
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
    Orientation orientation = MediaQuery.of(context).orientation;
    double calenderTitleFontSize = ResponsiveUtils.getCalenderTitleFontSize(screenWidth, orientation);
    double calenderFontSize = ResponsiveUtils.getCalenderFontSize(screenWidth, orientation);

    double EventMainTtileFontSize = ResponsiveUtils.getEventMainTitleFS(screenWidth, orientation);
    double ElevationButtonPadding = ResponsiveUtils.getElevationButtonPadding(screenWidth, orientation);

    // 현재 시간을 한 번만 가져옴
    return Scaffold(
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2040, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedEvents.value = _getEventsForDay(selectedDay);
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEventsForMonth();
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(fontSize: calenderFontSize),
              weekendTextStyle: TextStyle(fontSize: calenderFontSize),
              disabledTextStyle: TextStyle(fontSize: calenderFontSize),
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, events) => Container(
                margin: EdgeInsets.all(fontSizeXLarge * 0.25),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(color: Colors.white, fontSize: calenderFontSize),
                ),
              ),
              todayBuilder: (context, date, events) => Container(
                margin: EdgeInsets.all(fontSizeXLarge * 0.25),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(color: Colors.white, fontSize: calenderFontSize),
                ),
              ),
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final event = events.first;
                  final participant = event.participants.firstWhere(
                        (p) => p.participantId == event.myParticipantId,
                    orElse: () => event.participants[0],
                  );

                  String statusType = participant.statusType;
                  Color statusColor = _getStatusColor(statusType);

                  return Positioned(
                    child: Container(
                      width: calenderFontSize / 2,
                      height: calenderFontSize / 2,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(fontSize: calenderTitleFontSize),
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Colors.black,
                size: width * 0.06,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Colors.black,
                size: width * 0.06,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: height * 0.005, horizontal: width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '오늘의 일정',
                  style: TextStyle(fontSize: EventMainTtileFontSize, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    _navigateToEventCreation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: ElevationButtonPadding, vertical: height * 0.008,),
                    minimumSize: Size(width * 0.18, height * 0.012),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ElevationButtonPadding),
                    ),
                  ),
                  child: Text(
                    '일정 추가',
                    style: TextStyle(color: Colors.white, fontSize: calenderFontSize),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  // clubState를 이용해 메시지를 조건부로 변경
                  final emptyText = clubState.clubList.isEmpty
                      ? "참여 중인 모임이 없어요.\n먼저 모임에 참여하시거나\n새로운 모임을 만들어 주세요."
                      : "일정 추가 버튼을 눌러\n이벤트를 만들어보세요.";
                  if (value.isEmpty) {
                    return Center(
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_note,
                                  size: width * 0.25,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: height * 0.02),
                                Text(
                                  emptyText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: EventMainTtileFontSize - 4,
                                    color: Colors.grey,
                                  ),
                                )
                              ]
                          ),
                        )
                    );
                  }
                }
                // 이벤트가 있을 경우 기존 ListView.builder로 이벤트 목록을 보여줍니다.
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    final participant = event.participants.firstWhere(
                          (p) => p.participantId == event.myParticipantId,
                      orElse: () => event.participants[0],
                    );

                    String statusType = participant.statusType;
                    Color statusColor = _getStatusColor(statusType);

                    return Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: width * 0.02, vertical: height * 0.003),
                      padding: EdgeInsets.all(width * 0.03),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: statusColor, width: width * 0.005),
                        borderRadius:
                        BorderRadius.circular(width * 0.03),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.club!.name,
                            style: TextStyle(fontSize: width * 0.03),
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            event.eventTitle,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: EventMainTtileFontSize),
                          ),
                          SizedBox(height: height * 0.005),
                          Text('시작 시간: ${event.startDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: calenderFontSize)),
                          Text('인원수: 참석 ${event.participants.length}명', style: TextStyle(fontSize: calenderFontSize)),
                          Text('장소: ${event.site}', style: TextStyle(fontSize: calenderFontSize)),
                          Row(
                            children: [
                              _buildStatusButton(
                                'ACCEPT', statusType, () async {
                                  await _handleStatusChange('ACCEPT', participant.participantId, event);
                                },
                                event.startDateTime, // 이벤트 시작 시간 전달
                              ),
                              SizedBox(width: width * 0.015),
                              _buildStatusButton(
                                  'PARTY', statusType, () async {
                                  await _handleStatusChange('PARTY', participant.participantId, event);
                                },
                                event.startDateTime, // 이벤트 시작 시간 전달
                              ),
                              SizedBox(width: width * 0.015),
                              _buildStatusButton(
                                'DENY', statusType, () async {
                                  await _handleStatusChange('DENY', participant.participantId, event);
                                },
                                event.startDateTime, // 이벤트 시작 시간 전달
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top: height * 0.005),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _navigateToEventDetail(event);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(
                                      vertical: height * 0.005, // 반응형 상하 패딩
                                      horizontal: width * 0.02, // 반응형 좌우 패딩
                                    ),
                                    minimumSize: Size(width * 0.2, height * 0.04), // 최소 크기 설정
                                  ),
                                  child: Text(
                                    '세부 정보 보기',
                                    style: TextStyle(color: Colors.black, fontSize: calenderTitleFontSize),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _handleButtonPress(event, statusType),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(
                                      vertical: height * 0.005, // 반응형 상하 패딩
                                      horizontal: width * 0.02, // 반응형 좌우 패딩
                                    ),
                                    minimumSize: Size(width * 0.2, height * 0.04), // 최소 크기 설정
                                  ),
                                  child: Text(
                                    _getButtonText(event),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: calenderTitleFontSize,
                                      color: currentTime.isBefore(event.startDateTime)
                                          ? Colors.grey // 비활성화된 텍스트 색상
                                          : Colors.black, // 활성화된 텍스트 색상
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEventCreation() async {
    // 클럽 상태 업데이트를 명시적으로 기다립니다.
    await ref.read(clubStateProvider.notifier).fetchClubs();
    final clubState = ref.read(clubStateProvider);
    debugPrint("Club list length: ${clubState.clubList.length}"); // 디버깅 로그

    final hasClubs = clubState.clubList.isNotEmpty;
    if (!hasClubs) {
      // 모임이 없을 경우 안내 메시지 다이알로그
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("모임 정보 없음"),
            content: const Text(
              "현재 참여 중인 모임이 없어요.\n먼저 모임에 참여하시거나 새로운 모임을 만들어 주세요.\n(모임이 있어야 이벤트 생성이 가능합니다.)",
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("확인"),
              ),
            ],
          );
        },
      );
    } else {
      // 모임이 있다면 이벤트 생성 페이지로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventsCreate1(startDay: _focusedDay)),
      );
      if (result == true) {
        await _loadEventsForMonth();
      }
    }
  }

  void _navigateToEventDetail(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event),
      ),
    );

    if (result == true) {
      // 이벤트 삭제 후 목록 새로고침
      await _loadEventsForMonth();
    }
  }

  Color _getStatusColor(String statusType) {
    switch (statusType) {
      case 'PARTY':
        return const Color(0xFF4D08BD);
      case 'ACCEPT':
        return const Color(0xFF08BDBD);
      case 'DENY':
        return const Color(0xFFF21B3F);
      case 'PENDING':
      default:
        return const Color(0xFF7E7E7E);
    }
  }

  Widget _buildStatusButton(String status, String selectedStatus, VoidCallback onPressed, DateTime eventStartDateTime) {
    // 버튼이 선택된 상태인지 확인
    final bool isSelected = status == selectedStatus;
    // 이벤트가 과거인지 확인
    final bool isPastEvent = eventStartDateTime.isBefore(currentTime);
    // 선택된 상태에 따라 버튼의 색상을 결정
    final Color backgroundColor = isSelected
        ? _getStatusColor(status) // 선택된 상태이면 해당 색상을 사용
        : const Color(0xFF7E7E7E); // 선택되지 않은 상태일 때는 기본 회색을 사용

    // 버튼의 모양과 스타일을 정의
    return ElevatedButton(
      onPressed: isPastEvent ? null : onPressed, // 과거 이벤트면 버튼 비활성화
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // 비활성화된 버튼 스타일 유지
        disabledBackgroundColor: backgroundColor.withOpacity(0.6),
      ),
      child: Row(
        children: [
          Icon(
            status == selectedStatus ? Icons.check_circle : Icons.radio_button_unchecked,
            color: Colors.white,
            size: appBarIconSize - 4,
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status), // 상태에 맞는 텍스트를 가져오기
            style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
          ),
        ],
      ),
    );
  }


  String _getStatusText(String status) {
    switch (status) {
      case 'ACCEPT':
        return '참석';
      case 'PARTY':
        return '참석 · 회식';
      case 'DENY':
        return '불참';
      default:
        return '';
    }
  }

  Future<void> _handleStatusChange(String newStatus, int participantId, Event event) async {
    // 상태를 업데이트
    bool success = await _participantService.updateParticipantStatus(participantId, newStatus);
    final participantNotifier = ref.read(participantStateProvider.notifier);
    await participantNotifier.updateParticipantStatus(participantId, newStatus);

    if (success) {
      setState(() {
        // 해당 이벤트의 참가자의 상태를 업데이트
        final participant = event.participants.firstWhere(
              (p) => p.participantId == participantId,
        );
        participant.statusType = newStatus;

        // TODO: 잘 반영이 안 됨. 반영되도록 수정 필요
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    }
  }

  void _handleButtonPress(Event event, String statusType) {
    // 이미 종료된 이벤트면 '결과 조회'
    if (currentTime.isAfter(event.endDateTime)) {
      _navigateToResultPage(event);
      return;
    }

    // 이벤트가 시작되었고, 내 상태가 ACCEPT/PARTY라면
    if (currentTime.isAfter(event.startDateTime) &&
        (statusType == 'ACCEPT' || statusType == 'PARTY')) {
      // Riverpod에서 게임 진행 여부 가져오기
      final bool gameInProgress =
          ref.read(gameInProgressProvider)[event.eventId] ?? false;

      // 아직 게임 중이 아니라면, 여기서 게임 중으로 세팅
      if (!gameInProgress) {
        ref.read(gameInProgressProvider.notifier).startGame(event.eventId);
      }

      // 이후 스코어카드 페이지로 이동
      _navigateToGameStartPage(event);
    }
  }


  String _getButtonText(Event event) {
    if (currentTime.isAfter(event.endDateTime)) {
      return '결과 조회';
    } else if (currentTime.isAfter(event.startDateTime)) {
      // Riverpod에서 현재 '게임 중'인지 확인
      final bool gameInProgress =
      ref.watch(gameInProgressProvider.select((map) => map[event.eventId] ?? false));
      return gameInProgress ? '게임 진행 중' : '게임 시작';
    } else {
      return _formatTimeDifference(event.startDateTime);
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

}