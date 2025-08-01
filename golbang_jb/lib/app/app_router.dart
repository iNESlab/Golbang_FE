import 'dart:developer';

import 'package:go_router/go_router.dart';
import 'package:golbang/pages/community/community_main.dart';
import 'package:golbang/pages/logins/login.dart';
import 'package:golbang/pages/signup/signup.dart';
import 'package:golbang/pages/logins/signup_complete.dart';
import 'package:golbang/pages/home/home_page.dart';

import '../main.dart';
import '../pages/event/detail/event_detail.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TokenCheck(), // 로그인 여부 체크 후 리디렉션 처리
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/signupComplete',
      builder: (context, state) => const SignupComplete(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return HomePage();
      },
    ),

    GoRoute(
      path: '/events/:eventId',
      builder: (context, state) {
        final eventId = int.tryParse(state.pathParameters['eventId']!); // <-- 중요
        return EventDetailPage(eventId: eventId);  // <-- 여기가 핵심
      },
    ),
    GoRoute(
      path: '/club/:clubId',
      builder: (context, state) {
        final clubId = int.tryParse(state.pathParameters['clubId']!); // <-- 중요
        return CommunityMain(clubId: clubId);
        // TODO: 지금 커뮤니티는 API호출 없이 상태관리로만 진행됨 => 라우터로 접속시, API사용하게 해야함
      }
    ),
  ],
);
