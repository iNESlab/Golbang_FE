import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/global_config.dart';

import 'package:golbang/models/bookmark.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/models/user_account.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/widgets/sections/bookmark_section.dart';
import 'package:golbang/widgets/sections/groups_section.dart';
import 'package:golbang/widgets/common/section_with_scroll.dart';
import 'package:golbang/widgets/sections/upcoming_events.dart';
import 'package:golbang/pages/event/event_main.dart';
import 'package:golbang/pages/group/group_main.dart';
import 'package:golbang/pages/profile/profile_screen.dart';

import 'package:golbang/services/group_service.dart';
import 'package:golbang/services/user_service.dart';
import '../../repoisitory/secure_storage.dart';
import 'package:golbang/pages/notification/notification_history_page.dart';

import 'package:get/get.dart';

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
    _selectedIndex = Get.arguments?['initialIndex'] ?? 0;
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryPage(),
                ),
              );
            },
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

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulate fetching user token
    final storage = ref.watch(secureStorageProvider);
    final UserService userService = UserService(storage);
    final GroupService groupService = GroupService(storage);
    final EventService eventService = EventService(storage);
    DateTime _focusedDay = DateTime.now();

    String date = '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-01';
    print(date);

    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([
          userService.getUserInfo(),
          //Future.value(GlobalConfig.bookmarks),
          eventService.getEventsForMonth(date: date),
          groupService.getUserGroups(), // 그룹 데이터를 비동기적으로 가져옴
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Snapshot에서 데이터를 가져옴
            UserAccount userAccount = snapshot.data![0];
            List<Event> events = snapshot.data![1];
            List<Group> groups = snapshot.data![2];
            /*
            print(userAccount);
            if (userAccount.fcmToken == null) {
              // FCM 토큰이 없을 때 새로 FCM 토큰을 얻고 서버에 업데이트
              Future.microtask(() async {
                await _getAndUpdateFCMToken(userService, userAccount);
              });
            }
            */
            return Column(
              children: <Widget>[
                SizedBox(
                  height: 140,
                  child: SectionWithScroll(
                    title: '즐겨찾기',
                    child: BookmarkSection(userAccount: userAccount),
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

/*
Future<void> _getAndUpdateFCMToken(UserService userService, UserAccount userAccount) async {
  try {
    // FCM 토큰 가져오기
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();
    print("if null");
    if (fcmToken != null) {
      print("null");
      // FCM 토큰을 서버에 업데이트
      await userService.updateUserInfo2(
        userId: userAccount.userId,
        name: userAccount.name,
        email: userAccount.email,
        phoneNumber: userAccount.phoneNumber,
        handicap: userAccount.handicap,
        address: userAccount.address,
        dateOfBirth: userAccount.dateOfBirth,
        studentId: userAccount.studentId,
        profileImage: (userAccount.profileImage != null && userAccount.profileImage!.isNotEmpty)
            ? File(userAccount.profileImage!)
            : null,
        fcmToken: fcmToken,  // 새로운 FCM 토큰 서버에 저장
      );
      print('FCM 토큰이 서버에 업데이트되었습니다: $fcmToken');
    }
  } catch (e) {
    print('FCM 토큰 가져오기 실패: $e');
  }
}
*/
