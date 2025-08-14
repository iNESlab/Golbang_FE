import 'package:go_router/go_router.dart';
import 'package:golbang/app/routes/auth_routes.dart';
import 'package:golbang/app/routes/club_routes.dart';
import 'package:golbang/app/routes/etc_routes.dart';
import 'package:golbang/app/routes/event_routes.dart';
import 'package:golbang/app/routes/user_routes.dart';

import '../main.dart';
import '../pages/club/club_main.dart';
import '../pages/event/event_main.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_screen.dart';
import 'main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/app/home',
  navigatorKey: navigatorKey,

  // 레거시 경로를 /app/* 로 강제 정규화 (웹 전용 경로는 제외)
  redirect: (context, state) {
    final loc = state.uri.toString();

    // 웹뷰/브라우저 전용 링크는 건들지 않음
    if (loc.startsWith('/calculator/') || loc.startsWith('/calculate/')) {
      return null;
    }

    // 이미 /app/ 로 시작하면 통과
    if (loc.startsWith('/app/')) return null;

    // 루트/레거시 경로는 /app 프리픽스로 보정
    // 예: /home -> /app/home
    const legacyToApp = <String, String>{
      '/': '/app/home',
      '/home': '/app/home',
      '/events': '/app/events',
      '/clubs': '/app/clubs',
      '/user': '/app/user',
    };
    if (legacyToApp.containsKey(loc)) return legacyToApp[loc]!;

    // 그 외엔 일괄 프리픽스 부착 (중복 슬래시 방지)
    if (!loc.startsWith('/app')) {
      final normalized = loc.startsWith('/') ? '/app$loc' : '/app/$loc';
      return normalized;
    }
    return null;
  },

  routes: [
    // 앱 공통 프레임
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/app/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/app/events',
          builder: (context, state) => const EventPage(),
        ),
        GoRoute(
          path: '/app/clubs',
          builder: (context, state) => const ClubMainPage(),
        ),
        GoRoute(
          path: '/app/user',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // 세부 라우트들도 전부 /app 프리픽스 사용하도록 정리
    ...clubRoutes,   // 내부에서 path가 /app/xxx 로 되어있어야 함
    ...eventRoutes,  // "
    ...authRoutes,   // "
    ...userRoutes,   // "
    ...etcRoutes,    // "
  ],
);
