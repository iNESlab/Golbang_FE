import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/app/routes/auth_routes.dart';
import 'package:golbang/app/routes/club_routes.dart';
import 'package:golbang/app/routes/etc_routes.dart';
import 'package:golbang/app/routes/event_routes.dart';
import 'package:golbang/app/routes/user_routes.dart';
import 'package:golbang/app/current_route_service.dart';

import '../main.dart';
import '../pages/club/club_main.dart';
import '../pages/event/event_main.dart';
import '../pages/home/home_page.dart';
import '../pages/logins/login.dart';
import '../pages/profile/profile_screen.dart';
import 'main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/app', // '/app'이면 매칭이 없어 404 날 수 있어요. 홈으로 시작 권장
  navigatorKey: navigatorKey,
  routes: [
    // 앱 공통 프레임
    ShellRoute(
      builder: (context, state, child) {
        // 쿼리 파라미터에서 refresh 추출
        final refresh = state.uri.queryParameters['refresh'] ?? '';
        return KeyedSubtree(
          // refresh 값이 바뀌면 Shell 하위 트리 모두 새로 구성
          key: ValueKey('shell-$refresh'),
          child: MainScaffold(child: child),
        );
      },
      routes: [
        GoRoute(
          path: '/app/home',
          pageBuilder: (context, state) {
            final refresh = state.uri.queryParameters['refresh'] ?? '';
            return NoTransitionPage(
              // Page 자체에 키를 줘서 Navigator가 교체하도록
              key: ValueKey('home-page-$refresh'),
              child: const HomePage(), // 위젯 키까지 줄 필요는 보통 없음
            );
          },
        ),
        GoRoute(
          path: '/app/events',
          pageBuilder: (context, state) {
            final refresh = state.uri.queryParameters['refresh'] ?? '';
            return NoTransitionPage(
              key: ValueKey('events-page-$refresh'),
              // 필요하면 위젯에도 키 부여 (셋스테이트/프로바이더 캐시 깨고 싶을 때)
              child: EventPage(key: ValueKey('events-view-$refresh')),
            );
          },
        ),
        GoRoute(
          path: '/app/clubs',
          pageBuilder: (context, state) {
            final refresh = state.uri.queryParameters['refresh'] ?? '';
            return NoTransitionPage(
              key: ValueKey('clubs-page-$refresh'),
              child: const ClubMainPage(),
            );
          },
        ),
        GoRoute(
          path: '/app/user',
          pageBuilder: (context, state) {
            final refresh = state.uri.queryParameters['refresh'] ?? '';
            return NoTransitionPage(
              key: ValueKey('user-page-$refresh'),
              child: const ProfileScreen(),
            );
          },
        ),
      ],
    ),

    // 세부 라우트들도 pageBuilder 권장 (같은 원리로 key 부여)
    ...clubRoutes,   // 내부에서도 pageBuilder로 바꾸고 refresh 반영
    ...eventRoutes,  // "
    ...authRoutes,   // "
    ...userRoutes,   // "
    ...etcRoutes,    // "
  ],
);
