import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/event_create1.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import '../../models/event.dart';
import '../../provider/participant/participant_state_provider.dart';
import '../../utils/date_utils.dart';
import 'package:golbang/services/participant_service.dart';
import 'package:golbang/services/event_service.dart';
import 'event_detail.dart';

class EventPage extends ConsumerStatefulWidget {
  const EventPage({super.key});

  @override
  EventPageState createState() => EventPageState();
}
class EventPageState extends ConsumerState<EventPage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late EventService _eventService;
  late ParticipantService _participantService;

  final Map<DateTime, List<Event>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getUpcomingEvents());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMostRecentEvent();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = ref.watch(secureStorageProvider);
    _eventService = EventService(storage);
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
      print("Error loading events: $e");
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  List<Event> _getUpcomingEvents() {
    DateTime now = DateTime.now();
    return _events.entries
        .where((entry) => entry.key.isAfter(now) || isSameDay(entry.key, now))
        .expand((entry) => entry.value)
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.endDateTime));
  }

  void _showMostRecentEvent() {
    DateTime now = DateTime.now();
    if (_events.isEmpty) return;

    DateTime mostRecentDay = _events.keys
        .where((date) => date.isAfter(now) || isSameDay(date, now))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    _selectedDay = mostRecentDay;
    _focusedDay = mostRecentDay;
    _selectedEvents.value = _getEventsForDay(mostRecentDay);
    setState(() {});
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(6.0),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              todayBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(6.0),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: const TextStyle(color: Colors.white),
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
                      width: 7.0,
                      height: 7.0,
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
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Colors.black,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '오늘의 일정',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    _navigateToEventCreation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: const Size(50, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    '일정 추가',
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note, // 어울리는 아이콘을 선택하세요.
                              size: 100,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '일정 추가 버튼을 눌러\n이벤트를 만들어보세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            )
                          ]
                      )
                  );
                }
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
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: statusColor, width: 2.0),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventTitle,
                            style: const TextStyle(fontSize: 12.0),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            event.eventTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          const SizedBox(height: 8.0),
                          Text('시간: ${event.startDateTime.hour}:${event.startDateTime.minute}'),
                          Text('인원수: 참석 ${event.participants.length}명'),
                          Text('장소: ${event.location}'),
                          Row(
                            children: [
                              _buildStatusButton('ACCEPT', statusType, () async {
                                await _handleStatusChange('ACCEPT', participant.participantId, event);
                              }),
                              const SizedBox(width: 8),
                              _buildStatusButton('PARTY', statusType, () async {
                                await _handleStatusChange('PARTY', participant.participantId, event);
                              }),
                              const SizedBox(width: 8),
                              _buildStatusButton('DENY', statusType, () async {
                                await _handleStatusChange('DENY', participant.participantId, event);
                              }),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8.0),
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
                                  ),
                                  child: const Text(
                                    '세부 정보 보기',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                  child: const Text(
                                    '게임 시작',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EventsCreate1()),
    );

    if (result == true) {
      // 이벤트 생성 후 목록 새로고침
      await _loadEventsForMonth();
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
        return Color(0xFF4D08BD);
      case 'ACCEPT':
        return Color(0xFF08BDBD);
      case 'DENY':
        return Color(0xFFF21B3F);
      case 'PENDING':
      default:
        return Color(0xFF7E7E7E);
    }
  }

  Widget _buildStatusButton(String status, String selectedStatus, VoidCallback onPressed) {
    // 버튼이 선택된 상태인지 확인
    final bool isSelected = status == selectedStatus;
    // 선택된 상태에 따라 버튼의 색상을 결정
    final Color backgroundColor = isSelected
        ? _getStatusColor(status) // 선택된 상태이면 해당 색상을 사용
        : Color(0xFF7E7E7E); // 선택되지 않은 상태일 때는 기본 회색을 사용

    // 버튼의 모양과 스타일을 정의
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            status == selectedStatus ? Icons.check_circle : Icons.radio_button_unchecked,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status), // 상태에 맞는 텍스트를 가져오기
            style: const TextStyle(color: Colors.white),
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
}