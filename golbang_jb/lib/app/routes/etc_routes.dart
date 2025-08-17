import 'package:go_router/go_router.dart';

import '../../pages/event/result/new_peoria_web_view.dart';
import '../../pages/home/splash_screen.dart';
import '../../pages/notification/notification_history_page.dart';
import '../../pages/setting/feedback_page.dart';
import '../../pages/setting/setting_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



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
    path: '/app/new-peoria',
    builder: (context, state) {
      final query = state.uri.query; // ? 뒤의 쿼리스트링
      return NewPeoriaWebViewPage(
        url: '${dotenv.env['API_HOST']!}/calculator/upload/?$query',
      );
    },
  ),
  GoRoute(
    path: '/app/history',
    builder: (context, state) {
      return const NotificationHistoryPage();
    },
  ),
  GoRoute(
    path: '/app/setting',
    builder: (context, state) {
      return const SettingsPage();
    },
  ),
  GoRoute(
    path: '/app/splash',
    builder: (context, state) {
      return const SplashScreen();
    },
  ),
  GoRoute(
    path: '/app/feedback',
    builder: (context, state) {
      return const FeedbackPage();
    },
  ),

];
