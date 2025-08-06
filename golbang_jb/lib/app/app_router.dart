import 'package:go_router/go_router.dart';
import 'package:golbang/app/routes/auth_routes.dart';
import 'package:golbang/app/routes/club_routes.dart';
import 'package:golbang/app/routes/etc_routes.dart';
import 'package:golbang/app/routes/event_routes.dart';
import 'package:golbang/app/routes/home_routes.dart';
import 'package:golbang/app/routes/user_routes.dart';

import '../main.dart';
import '../models/user_account.dart';
import '../pages/club/club_main.dart';
import '../pages/event/event_main.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_screen.dart';
import 'main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  navigatorKey: navigatorKey,
  routes: [
    // ✅ Main 페이지용 ShellRoute
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child), // ← 여기서 AppBar + BottomNav 띄움
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventPage(),
        ),
        GoRoute(
          path: '/clubs',
          builder: (context, state) => const ClubMainPage(),
        ),
        GoRoute(
            path: '/user',
            builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // ✅ 그 외 모든 세부 라우트는 여기에 위치
    ...clubRoutes,
    ...eventRoutes,
    ...authRoutes,
    ...userRoutes,
    ...etcRoutes,
  ],
);
