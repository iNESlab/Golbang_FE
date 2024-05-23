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

  Future<List<Bookmark>> fetchBookmarks() async {
    return [
      Bookmark('내 프로필', '-15.9', 'G핸디'),
      Bookmark('스코어', '72(-1)', 'Par-Tee Time', '23.02.12'),
      Bookmark('기록', '100', '99등', '23.02.07'),
    ];
  }

  Future<List<Event>> fetchEvents() async {
    return [
      Event('Event 1', 'Group 1', '12:00 PM', 'Location 1', 10, 'Group A',
          '100', '완료', true),
      Event('Event 2', 'Group 2', '2:00 PM', 'Location 2', 20, 'Group B', '200',
          '미납', false),
    ];
  }

  Future<List<Group>> fetchGroups() async {
    return [
      Group('Group 1', true),
      Group('Group 2', false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([fetchBookmarks(), fetchEvents(), fetchGroups()]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Bookmark> bookmarks = snapshot.data![0];
            List<Event> events = snapshot.data![1];
            List<Group> groups = snapshot.data![2];

            return Column(
              children: <Widget>[
                SizedBox(
                  height: 150,
                  child: SectionWithScroll(
                    title: '즐겨찾기',
                    child: BookmarkSection(bookmarks: bookmarks),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SectionWithScroll(
                    title: '다가오는 이벤트 ${events.length}',
                    child: UpcomingEvents(events: events),
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: SectionWithScroll(
                    title: '내 모임 ${groups.length}',
                    child: GroupsSection(groups: groups),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class BookmarkSection extends StatelessWidget {
  final List<Bookmark> bookmarks;

  const BookmarkSection({super.key, required this.bookmarks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            bookmarks.map((bookmark) => _buildInfoCard(bookmark)).toList(),
      ),
    );
  }

  Widget _buildInfoCard(Bookmark bookmark) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
            bookmark.title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            bookmark.value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (bookmark.subtitle != null)
            Text(
              bookmark.subtitle!,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          if (bookmark.detail1 != null && bookmark.detail2 != null)
            Column(
              children: [
                Text(
                  bookmark.detail1!,
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  bookmark.detail2!,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
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
    final RegExp numberRegExp = RegExp(r'(\d+)');
    final Iterable<Match> matches = numberRegExp.allMatches(title);
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: title.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(color: Colors.green),
      ));
      start = match.end;
    }
    if (start < title.length) {
      spans.add(TextSpan(text: title.substring(start)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  children: spans,
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
        SizedBox(height: title.startsWith('내 모임') ? 1 : 4),
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
        Event('Event 1', 'Group 1', '12:00 PM', 'Location 1', 10, 'Group A',
            '100', '완료', true)
      ],
      DateTime(2024, 5, 15): [
        Event('Event 2', 'Group 2', '2:00 PM', 'Location 2', 20, 'Group B',
            '200', '미납', false)
      ],
    });

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getUpcomingEvents());
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
      ..sort((a, b) => a.date.compareTo(b.date));
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
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  Color markerColor;
                  switch (events[0].dinnerStatus) {
                    case '참석':
                      markerColor = Colors.cyan;
                      break;
                    case '불참':
                      markerColor = Colors.red;
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
                              const Text('참여 여부: '),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan,
                                  minimumSize: const Size(50, 30),
                                ),
                                child: const Text('참석',
                                    style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  minimumSize: const Size(50, 30),
                                ),
                                child: const Text('미정',
                                    style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  minimumSize: const Size(50, 30),
                                ),
                                child: const Text('불참',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8.0),
                            decoration: const BoxDecoration(
                              border:
                                  Border(top: BorderSide(color: Colors.grey)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                  child: const Text('세부 정보 보기'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                  child: const Text('게임 시작',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _focusedDay = DateTime.now();
            _selectedDay = DateTime.now();
            _selectedEvents.value = _getEventsForDay(_selectedDay!);
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.calendar_today),
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
  final List<Event> events;

  const UpcomingEvents({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _getBorderColor(event), width: 1.5),
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
                        if (event.isAdmin)
                          const Icon(Icons.admin_panel_settings,
                              color: Colors.green),
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
                                border: Border.all(
                                    color: _getBorderColor(event), width: 2.0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: _getBorderColor(event),
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
                                      color: _getBorderColor(event),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      event.paymentStatus,
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

  Color _getBorderColor(Event event) {
    if (event.paymentStatus == '완료') {
      return Colors.cyan;
    } else if (event.paymentStatus == '미납') {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }
}

class GroupsSection extends StatelessWidget {
  final List<Group> groups;

  const GroupsSection({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            bool isNew = groups[index].isNew;

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

class Bookmark {
  final String title;
  final String value;
  final String? subtitle;
  final String? detail1;
  final String? detail2;

  Bookmark(this.title, this.value, [this.subtitle, this.detail1, this.detail2]);

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      json['title'],
      json['value'],
      json['subtitle'],
      json['detail1'],
      json['detail2'],
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
  final bool isAdmin;

  Event(
      this.eventName,
      this.groupName,
      this.time,
      this.location,
      this.numberOfPeople,
      this.groupFormation,
      this.yardage,
      this.dinnerStatus,
      this.isAdmin);

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      json['eventName'],
      json['groupName'],
      json['time'],
      json['location'],
      json['numberOfPeople'],
      json['groupFormation'],
      json['yardage'],
      json['dinnerStatus'],
      json['isAdmin'],
    );
  }

  int get attending => numberOfPeople;
  int get pending => 0;
  List<String> get groupMembers => groupFormation.split(',');
  String get startPoint => location;
  String get paymentStatus => dinnerStatus;

  get date => null;
}

class Group {
  final String name;
  final bool isNew;

  Group(this.name, this.isNew);

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      json['name'],
      json['isNew'],
    );
  }
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}
