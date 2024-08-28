import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';
import 'package:golbang/models/bookmark.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/provider/user_token_provider.dart';
import 'package:golbang/widgets/sections/bookmark_section.dart';
import 'package:golbang/widgets/sections/groups_section.dart';
import 'package:golbang/widgets/common/section_with_scroll.dart';
import 'package:golbang/widgets/sections/upcoming_events.dart';

import 'package:golbang/pages/event/event_main.dart';
import 'package:golbang/pages/group/group_main.dart';
import 'package:golbang/pages/profile/profile_screen.dart';
import 'package:golbang/api.dart';
import 'package:provider/provider.dart'; // Import API functions

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // userToken을 초기화하기 위해 initState에서 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userTokenProvider = Provider.of<UserTokenProvider>(context, listen: false);
      userTokenProvider.setUserToken('token_john_doe');
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    EventPage(),
    GroupMainPage(),
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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate fetching user token
    final userTokenProvider = Provider.of<UserTokenProvider>(context);
    var userGroupsData = getUserGroups(userTokenProvider.userToken!);
    List<Group> userGroups = userGroupsData;

    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([
          Future.value(GlobalConfig.bookmarks),
          Future.value(GlobalConfig.events),
          Future.value(userGroups),
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
