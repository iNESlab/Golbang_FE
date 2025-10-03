import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/models/club.dart';
import 'package:golbang/models/user_account.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/widgets/sections/bookmark_section.dart';
import 'package:golbang/widgets/sections/groups_section.dart';
import 'package:golbang/widgets/common/section_with_scroll.dart';
import 'package:golbang/widgets/sections/upcoming_events.dart';
import 'package:golbang/services/group_service.dart';
import 'package:golbang/services/user_service.dart';
import 'package:golbang/services/statistics_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../../provider/club/club_state_provider.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  // Fetching services
  late final UserService userService;
  late final GroupService groupService;
  late final EventService eventService;
  late final StatisticsService statisticsService;

  late String date;
  late Future<List<dynamic>> _dataFuture;
  late List<Event> _events;
  
  // 🔧 추가: 타이머 기반 새로고침
  Timer? _refreshTimer;

  Future<List<dynamic>> _loadData() {
    return Future.wait([
      userService.getUserInfo(),
      eventService.getEventsForMonth(date: date),
      groupService.getUserGroups(),
      statisticsService.fetchOverallStatistics().catchError((e) {
        log('Error fetching overall statistics: $e');
        return OverallStatistics(
          averageScore: 0.0,
          bestScore: 0,
          handicapBestScore: 0,
          gamesPlayed: 0,
        );
      }),
    ]);
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }
  
  // 🔧 추가: unread count만 업데이트하는 메서드 (화면 새로고침 없음)
  Future<void> _refreshUnreadCountOnly() async {
    try {
      // clubStateProvider만 업데이트하여 unread count 새로고침
      await ref.read(clubStateProvider.notifier).fetchClubs();
      log('✅ unread count 업데이트 완료');
    } catch (e) {
      log('❌ unread count 업데이트 실패: $e');
    }
  }
  
  // 🔧 추가: 즉시 unread count 업데이트하는 메서드 (동기적)
  void _refreshUnreadCountImmediately() {
    try {
      log('🔄 홈 화면 포커스: unread count 즉시 업데이트 시작');
      
      // 동기적으로 clubStateProvider 업데이트
      ref.read(clubStateProvider.notifier).fetchClubs();
      log('✅ 홈 화면 포커스: unread count 즉시 업데이트 완료');
      
    } catch (e) {
      log('❌ 즉시 unread count 업데이트 실패: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    final storage = ref.read(secureStorageProvider);
    userService = UserService(storage);
    groupService = GroupService(storage);
    eventService = EventService(storage);
    statisticsService = StatisticsService(storage);

    final DateTime focusedDay = DateTime.now();
    date = '${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}-01';

    _dataFuture = _loadData();
    
    // 🔧 추가: 라이프사이클 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
    
    // 🔧 추가: 15초마다 unread count 새로고침 (화면 새로고침 없음)
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        log('🔄 타이머 기반 unread count 업데이트');
        _refreshUnreadCountOnly();
      }
    });
  }
  
  @override
  void dispose() {
    // 🔧 추가: 타이머 정리
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log('🔍 HomePage didChangeDependencies 호출됨');
    // 🔧 수정: 화면이 다시 포커스될 때 unread count 즉시 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('🔍 HomePage addPostFrameCallback 실행: _refreshUnreadCountImmediately 호출');
      _refreshUnreadCountImmediately(); // 즉시 unread count 업데이트
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 🔧 추가: 앱이 다시 활성화될 때 unread count만 업데이트
    if (state == AppLifecycleState.resumed) {
      log('🔄 앱 활성화: unread count 업데이트');
      _refreshUnreadCountOnly();
    }
  }


  @override
  Widget build(BuildContext context) {

    // 화면 크기 설정
    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
    Orientation orientation = MediaQuery.of(context).orientation;
    double bookmarkSectionHeight = orientation == Orientation.landscape ? screenHeight * 0.15 : screenHeight * 0.15;

    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: FutureBuilder(
          future: _dataFuture,
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }
            // 데이터 추출
            UserAccount userAccount = snapshot.data![0];
            List<Event> events = snapshot.data![1];
            events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
            List<Club> clubs = snapshot.data![2];
            OverallStatistics overallStatistics = snapshot.data![3] ?? OverallStatistics(
              averageScore: 0.0,
              bestScore: 0,
              handicapBestScore: 0,
              gamesPlayed: 0,
            );

            // UpcomingEvents 위젯의 필터링 로직과 동일하게 개수 계산
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final upcomingEventsCount = events.where((event) {
              final eventDay = DateTime(event.startDateTime.year, event.startDateTime.month, event.startDateTime.day);
              return !eventDay.isBefore(today); // 오늘 이전은 제외, 오늘 포함
            }).length;

            return Column(
              children: <Widget>[
                SizedBox(
                  height: bookmarkSectionHeight,
                  child: SectionWithScroll(
                    title: '대시보드',
                    child: BookmarkSection(
                      userAccount: userAccount,
                      overallStatistics: overallStatistics, // Pass overall statistics
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SectionWithScroll(
                    title: '다가오는 일정 $upcomingEventsCount',
                    child: UpcomingEvents(
                        events: events, // 필터링하지 않은 전체 리스트 전달
                        date: date,
                        onEventUpdated: () async {
                          await _refreshData(); // 데이터 다시 로드
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.18,
                  child: SectionWithScroll(
                    title: '내 모임 ${clubs.length}',
                    child: GroupsSection(), // 🔧 수정: clubs props 제거, clubStateProvider 사용
                  ),
                ),
              ],
            );
          }

      ),
    ),
    );
  }
}