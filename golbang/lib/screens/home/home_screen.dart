import 'package:flutter/material.dart';
import '../../widgets/bookmark_section.dart';
import '../../widgets/upcoming_events.dart';
import '../../widgets/groups_section.dart';
import '../../models/bookmark.dart';
import '../../models/event.dart';
import '../../models/group.dart';
import '../../widgets/section_with_scroll.dart';
import '../events/events_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

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
