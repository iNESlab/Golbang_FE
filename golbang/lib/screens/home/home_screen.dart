import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';
import 'package:golbang/models/bookmark.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/widgets/bookmark_section.dart';
import 'package:golbang/widgets/groups_section.dart';
import 'package:golbang/widgets/section_with_scroll.dart';
import 'package:golbang/widgets/upcoming_events.dart';
import 'package:golbang/screens/events/events_screen.dart';
import 'package:golbang/screens/groups/groups_screen.dart';
import 'package:golbang/screens/profile/profile_screen.dart';


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
    GroupsScreen(),
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
          style: TextStyle(color: Colors.green, fontSize: 25),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
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
              spreadRadius: 1,
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
              label: '일정',
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
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([
          Future.value(GlobalConfig.bookmarks),
          Future.value(GlobalConfig.events),
          Future.value(GlobalConfig.groups),
        ]),
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
                  height: 140,
                  child: SectionWithScroll(
                    title: '즐겨찾기',
                    child: BookmarkSection(bookmarks: bookmarks),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SectionWithScroll(
                    title: '다가오는 일정 ${events.length}',
                    child: UpcomingEvents(events: events),
                  ),
                ),
                SizedBox(
                  height: 130,
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