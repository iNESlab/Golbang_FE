import 'package:go_router/go_router.dart';

import '../../pages/home/splash_screen.dart';
import '../../pages/notification/notification_history_page.dart';
import '../../pages/setting/feedback_page.dart';
import '../../pages/setting/setting_page.dart';


final List<GoRoute> etcRoutes = [
  // GoRoute(
  //   path: '/articles/:articleId/edit',
  //   builder: (context, state) {
  //     return null;
  //   },
  // ),
  // GoRoute(
  //   path: '/articles/:articleId',
  //   builder: (context, state) {
  //     return null;
  //   },
  // ),
  // GoRoute(
  //   path: '/articles/new',
  //   builder: (context, state) {
  //     final extra = state.extra as Map<String, dynamic>?;
  //     return CommunityPostCard(post: {});
  //   },
  // ),
  GoRoute(
    path: '/history',
    builder: (context, state) {
      return const NotificationHistoryPage();
    },
  ),
  GoRoute(
    path: '/setting',
    builder: (context, state) {
      return const SettingsPage();
    },
  ),
  GoRoute(
    path: '/splash',
    builder: (context, state) {
      return const SplashScreen();
    },
  ),
  GoRoute(
    path: '/feedback',
    builder: (context, state) {
      return const FeedbackPage();
    },
  ),

];
