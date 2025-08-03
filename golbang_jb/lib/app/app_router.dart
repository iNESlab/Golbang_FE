import 'package:go_router/go_router.dart';
import 'package:golbang/app/routes/auth_routes.dart';
import 'package:golbang/app/routes/club_routes.dart';
import 'package:golbang/app/routes/etc_routes.dart';
import 'package:golbang/app/routes/event_routes.dart';
import 'package:golbang/app/routes/home_routes.dart';
import 'package:golbang/app/routes/user_routes.dart';

import '../main.dart';


final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    ...authRoutes,
    ...eventRoutes,
    ...clubRoutes,
    ...homeRoutes,
    ...userRoutes,
    ...etcRoutes,
  ],
);
