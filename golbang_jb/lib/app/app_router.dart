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
  initialLocation: '/app',
  navigatorKey: navigatorKey,

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
