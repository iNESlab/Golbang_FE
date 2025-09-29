import 'package:go_router/go_router.dart';
import 'package:golbang/pages/community/community_main.dart';

import '../../pages/club/club_create_page.dart';
import '../../pages/club/club_edit_page.dart';
import '../../pages/club/club_main.dart';
import '../../pages/club/club_search_page.dart';
import '../../pages/community/admin_settings_page.dart';
import '../../pages/community/member_list_page.dart';
import '../../pages/community/member_settings_page.dart';
import '../../pages/community/post/post_create_page.dart';

final List<GoRoute> clubRoutes = [
  GoRoute(
      path: '/app/clubs/new',
      builder: (context, state) {
        return const ClubCreatePage();
      }
  ),

  // /app/clubs/search
  GoRoute(
    path: '/app/clubs/search',
    pageBuilder: (context, state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const ClubSearchPage(),
      );
    },
  ),

  // /app/clubs/:clubId
  GoRoute(
      path: '/app/clubs/:clubId',
      builder: (context, state) {
        final clubId = int.tryParse(state.pathParameters['clubId']!);
        final extra = state.extra as Map<String, dynamic>?;

        return CommunityMain(
          clubId: clubId,
          from: extra?['from'],
        );
      },
      routes: [
        GoRoute(
          path: 'new-post',
          builder: (context, state) {
            final clubId = int.parse(state.pathParameters['clubId']!);
            return PostWritePage(
                clubId: clubId
            );
          },
        ),
        GoRoute(
            path: 'setting',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final clubId = int.parse(state.pathParameters['clubId']!);
              String role = extra?['role'] as String;

              if (role == 'admin') {
                return AdminSettingsPage(
                  clubId: clubId,
                );
              } else if (role == 'member') {
                return MemberSettingsPage(
                  clubId: clubId,
                );
              }
              return const ClubMainPage();
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  return const ClubEditPage();
                },
              ),
              GoRoute(
                path: 'members',
                builder: (context, state) {
                  final clubId = int.tryParse(state.pathParameters['clubId']!);
                  final extra = state.extra as Map<String, dynamic>?;
                  return MemberListPage(
                    clubId: clubId!,
                    isAdmin: extra?['isAdmin'] as bool,
                  );
                },
              ),
            ]
        ),
      ]
  ),
];