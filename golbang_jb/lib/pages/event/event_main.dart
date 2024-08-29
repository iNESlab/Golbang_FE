import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import '../../models/event.dart';
import '../../utils/date_utils.dart';
import 'package:golbang/global_config.dart'; // Import the global configuration

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventPage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Event>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  @override
  void initState() {
    super.initState();

    // Initialize _events with data from GlobalConfig
    for (var event in GlobalConfig.events) {
      DateTime eventDate = DateTime(event.time.year, event.time.month, event.time.day);

      if (_events.containsKey(eventDate)) {
        _events[eventDate]!.add(event);
      } else {
        _events[eventDate] = [event];
      }
    }

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getUpcomingEvents());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMostRecentEvent();
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
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  void _showMostRecentEvent() {
    DateTime now = DateTime.now();
    if (_events.isEmpty) return; // Handle case where there are no events

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
              headerTitleBuilder: (context, date) {
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                        _selectedEvents.value = _getEventsForDay(_selectedDay!);
                      });
                    },
                    child: Text(
                      '${date.year}년 ${date.month}월',
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  Color markerColor;
                  switch (events[0].attendanceStatus) {
                    case '참석':
                      markerColor = Colors.cyan;
                      break;
                    case '불참':
                      markerColor = Colors.red;
                      break;
                    case '참석·회식':
                      markerColor = Colors.deepPurple;
                      break;
                    default:
                      markerColor = Colors.black;
                  }
                  return Positioned(
                    bottom: 1,
                    child: _buildEventsMarker(date, events, markerColor),
                  );
                }
                return Container();
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
                  onPressed: () {},
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
                    Color borderColor;
                    Color attendColor = Colors.grey;
                    Color attendDinnerColor = Colors.grey;
                    Color absentColor = Colors.grey;

                    switch (value[index].attendanceStatus) {
                      case '참석':
                        borderColor = Colors.cyan;
                        attendColor = Colors.cyan;
                        break;
                      case '불참':
                        borderColor = Colors.red;
                        absentColor = Colors.red;
                        break;
                      case '참석·회식':
                        borderColor = Colors.deepPurple;
                        attendDinnerColor = Colors.deepPurple;
                        break;
                      default:
                        borderColor = Colors.grey;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 2.0),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value[index].group,
                            style: const TextStyle(fontSize: 12.0),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            value[index].title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          const SizedBox(height: 8.0),
                          Text('시간: ${value[index].time.hour}:${value[index].time.minute}'),
                          Text('인원수: 참석 ${value[index].participants}명'),
                          Text('장소: ${value[index].location}'),
                          Row(
                            children: [
                              const Text('참석 여부: '),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: attendColor,
                                  minimumSize: const Size(50, 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text(
                                  '참석',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: attendDinnerColor,
                                  minimumSize: const Size(50, 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text(
                                  '참석·회식',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: absentColor,
                                  minimumSize: const Size(50, 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text(
                                  '불참',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
                                  onPressed: () {},
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
                                        color: Colors.black),
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

  Widget _buildEventsMarker(DateTime date, List<Event> events, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      width: 7.0,
      height: 7.0,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
    );
  }
}
