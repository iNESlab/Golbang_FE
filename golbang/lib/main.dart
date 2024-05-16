import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:collection';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOLBANG MAIN PAGE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const EventsScreen(),
    const GroupsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'GOLBANG',
          style: TextStyle(
            color: Colors.green,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note),
              label: '이벤트',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: '모임',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '내 정보',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 150,
            child: SectionWithScroll(
              title: '즐겨찾기',
              child: BookmarkSection(),
            ),
          ),
          Expanded(
            flex: 5,
            child: SectionWithScroll(
              title: '다가오는 이벤트',
              child: UpcomingEvents(),
            ),
          ),
          SizedBox(
            height: 150,
            child: SectionWithScroll(
              title: '내 모임',
              child: GroupsSection(),
            ),
          ),
        ],
      ),
    );
  }
}

class BookmarkSection extends StatelessWidget {
  const BookmarkSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildInfoCard('내 프로필', '-15.9'),
          _buildInfoCard('스코어', '72(-1)'),
          _buildInfoCard('기록', '100'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {double width = 100}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class SectionWithScroll extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionWithScroll({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
        SizedBox(height: title == '내 모임' ? 1 : 4),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  EventsScreenState createState() => EventsScreenState();
}

class EventsScreenState extends State<EventsScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Event>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getHashCode,
  )..addAll({
      DateTime(2024, 5, 14): [
        const Event('Event 1', 'Group 1', '12:00 PM', 'Location 1', 10,
            'Group A', '100', '참석')
      ],
      DateTime(2024, 5, 15): [
        const Event('Event 2', 'Group 2', '2:00 PM', 'Location 2', 20,
            'Group B', '200', '불참')
      ],
    });

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '이벤트',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
        ),
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
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                Color markerColor;
                switch (events[0].dinnerStatus) {
                  case '참석':
                    markerColor = Colors.red;
                    break;
                  case '불참':
                    markerColor = Colors.black;
                    break;
                  default:
                    markerColor = Colors.purple;
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
                '다가오는 이벤트',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                child: const Text(
                  '이벤트 추가',
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
              return ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 2.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value[index].groupName,
                          style: const TextStyle(fontSize: 12.0),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          value[index].eventName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text('시간: ${value[index].time}'),
                        Text(
                            '인원수: 참석 ${value[index].attending}명, 미정 ${value[index].pending}명'),
                        Text('조: ${value[index].groupMembers.join(', ')}'),
                        Text('시작 지점: ${value[index].startPoint}'),
                        Text('야드: ${value[index].yardage}'),
                        Row(
                          children: [
                            const Text('회식 참여 여부: '),
                            ElevatedButton(
                              onPressed: () {
                                // 참석 버튼 로직
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                minimumSize: const Size(50, 30), // 크기 조정
                              ),
                              child: const Text('참석',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () {
                                // 미정 버튼 로직
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                minimumSize: const Size(50, 30), // 크기 조정
                              ),
                              child: const Text('미정',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () {
                                // 불참 버튼 로직
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size(50, 30), // 크기 조정
                              ),
                              child: const Text('불참',
                                  style: TextStyle(fontSize: 12)),
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
                                onPressed: () {
                                  // 세부 정보 보기 로직
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green, // 텍스트 색상 변경
                                ),
                                child: const Text('세부 정보 보기'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // 게임 시작 로직
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green, // 텍스트 색상 변경
                                ),
                                child: const Text('게임 시작',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Groups Page"));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Profile Page"));
  }
}

class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            Color borderColor;
            Color buttonColor;
            String paymentStatus;
            if (index % 3 == 0) {
              borderColor = Colors.cyan;
              buttonColor = Colors.cyan;
              paymentStatus = '완료';
            } else if (index % 3 == 1) {
              borderColor = Colors.black;
              buttonColor = Colors.black;
              paymentStatus = '미납';
            } else {
              borderColor = Colors.red;
              buttonColor = Colors.red;
              paymentStatus = '미납';
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(4),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('모임 이름 ${index + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.flag, color: borderColor),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: borderColor, width: 2.0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: borderColor,
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '이벤트 날짜와 시간 ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('장소: 장소 ${index + 1}'),
                              Row(
                                children: [
                                  const Text('회비 납부 '),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: buttonColor,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      paymentStatus,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GroupsSection extends StatelessWidget {
  const GroupsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 10,
          itemBuilder: (context, index) {
            bool isNew = index % 2 == 0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNew ? Colors.green : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 0.5,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                backgroundImage: AssetImage('assets/images/dragon.jpeg'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Event {
  final String eventName;
  final String groupName;
  final String time;
  final String location;
  final int numberOfPeople;
  final String groupFormation;
  final String yardage;
  final String dinnerStatus;

  const Event(
    this.eventName,
    this.groupName,
    this.time,
    this.location,
    this.numberOfPeople,
    this.groupFormation,
    this.yardage,
    this.dinnerStatus,
  );

  // Add missing getters
  int get attending => numberOfPeople; // Placeholder for actual logic
  int get pending => 0; // Placeholder for actual logic
  List<String> get groupMembers => groupFormation.split(','); // Example logic
  String get startPoint => location; // Example logic

  @override
  String toString() => eventName;
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}
