import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/event_create1.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import '../../models/event.dart';
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

    // Riverpod의 ref 사용하여 초기화
    final storage = ref.watch(secureStorageProvider);
    _eventService = EventService(storage);

    // Load events from API for the current month
    _loadEventsForMonth();
  }

  Future<void> _loadEventsForMonth() async {
    final storage = ref.watch(secureStorageProvider); // Riverpod의 ref 사용
    final eventService = EventService(storage);

    // 날짜 설정 (현재 달로 설정)
    String date = '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-01';

    // API 호출하여 이벤트 불러오기
    List<Event> events = await eventService.getEventsForMonth(date: date);

    // 이벤트를 달력에 로드
    setState(() {
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
    });
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

  // 기존의 ParticipantService를 활용하는 메서드
  Future<void> _updateParticipantStatus(int participantId, String statusType) async {
    final storage = ref.watch(secureStorageProvider);
    final participantService = ParticipantService(storage);
    await participantService.updateParticipantStatus(participantId, statusType);
    setState(() {});
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
              _loadEventsForMonth(); // 페이지가 바뀔 때마다 이벤트 로드
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
                  // 첫 번째 이벤트의 상태를 기반으로 색상 설정
                  final event = events.first;
                  String statusType = event.participants[0].statusType;
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventsCreate1()),
                    );
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
                  return const Center(child: Text('일정이 없습니다.'));
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    String statusType = value[index].participants[0].statusType;
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
                            value[index].eventTitle,
                            style: const TextStyle(fontSize: 12.0),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            value[index].eventTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          const SizedBox(height: 8.0),
                          Text('시간: ${value[index].startDateTime.hour}:${value[index].startDateTime.minute}'),
                          Text('인원수: 참석 ${value[index].participants.length}명'),
                          Text('장소: ${value[index].location}'),
                          Row(
                            children: [
                              const Text('참석 여부: '),
                              _buildStatusButton(statusType, statusColor),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailPage(event: value[index]),
                                      ),
                                    );
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

  Widget _buildStatusButton(String statusType, Color statusColor) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: statusColor,
        minimumSize: const Size(50, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        statusType,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
