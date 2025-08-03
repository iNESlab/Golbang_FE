import 'package:go_router/go_router.dart';
import 'package:golbang/pages/community/community_main.dart';

import '../../pages/club/club_create_page.dart';
import '../../pages/club/club_edit_page.dart';
import '../../pages/club/club_main.dart';
import '../../pages/community/admin_settings_page.dart';
import '../../pages/community/member_list_page.dart';
import '../../pages/community/member_settings_page.dart';
import '../../pages/community/post/post_create_page.dart';

final List<GoRoute> clubRoutes = [
  GoRoute(
    path: '/clubs',
    builder: (context, state) => const ClubMainPage(), // 이벤트 목록 페이지
    routes: [
      GoRoute(
          path: 'new',
          builder: (context, state) {
            return const ClubCreatePage();
          }
      ),
      GoRoute(
        path: ':clubId',
        builder: (context, state) {
          final clubId = int.tryParse(state.pathParameters['clubId']!);
          final extra = state.extra as Map<String, dynamic>?;

          return CommunityMain(
            clubId: clubId,
            from: extra?['from'],
          );
        },
      ),
      GoRoute(
        path: ':clubId/setting',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          String role = extra?['role'] as String;

          if (role == 'admin') {
            return AdminSettingsPage(
              clubId: extra?['clubId'] as int,
            );
          } else if (role == 'member') {
            return MemberSettingsPage(
              clubId: extra?['clubId'] as int,
            );
          }
          return const ClubMainPage();
        },
      ),
      GoRoute(
        path: ':clubId/edit',
        builder: (context, state) {
          return const ClubEditPage();
        },
      ),
      GoRoute(
        path: ':clubId/members',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MemberListPage(
            clubId: extra?['clubId'] as int,
            isAdmin: extra?['isAdmin'] as bool,
          );
        },
      ),
      GoRoute(
        path: ':clubId/new-post',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PostWritePage(
            clubId: extra?['clubId'] as int,
          );
        },
      ),
    ],
  ),
];
