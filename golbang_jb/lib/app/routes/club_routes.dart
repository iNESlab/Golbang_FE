import 'package:flutter/cupertino.dart';
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
  // /app/clubs/new
  GoRoute(
    path: '/app/clubs/new',
    pageBuilder: (context, state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const ClubCreatePage(),
      );
    },
  ),

  // /app/clubs/:clubId
  GoRoute(
    path: '/app/clubs/:clubId',
    pageBuilder: (context, state) {
      final clubId = int.tryParse(state.pathParameters['clubId'] ?? '');
      final extra = state.extra as Map<String, dynamic>?;
      return NoTransitionPage(
        key: state.pageKey,
        child: CommunityMain(
          clubId: clubId,
          from: extra?['from'],
        ),
      );
    },
    routes: [
      // /app/clubs/:clubId/new-post
      GoRoute(
        path: 'new-post',
        pageBuilder: (context, state) {
          final clubId = int.parse(state.pathParameters['clubId']!);
          return NoTransitionPage(
            key: state.pageKey,
            child: PostWritePage(
              clubId: clubId,
            ),
          );
        },
      ),

      // /app/clubs/:clubId/setting
      GoRoute(
        path: 'setting',
        pageBuilder: (context, state) {
          final clubId = int.parse(state.pathParameters['clubId']!);
          final extra = state.extra as Map<String, dynamic>?;
          final role = (extra?['role'] as String?) ?? '';

          Widget child;
          if (role == 'admin') {
            child = AdminSettingsPage(clubId: clubId);
          } else if (role == 'member') {
            child = MemberSettingsPage(clubId: clubId);
          } else {
            child = const ClubMainPage(); // fallback
          }

          return NoTransitionPage(
            key: state.pageKey,
            child: KeyedSubtree( child: child),
          );
        },
        routes: [
          // /app/clubs/:clubId/setting/edit
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const ClubEditPage(),
              );
            },
          ),

          // /app/clubs/:clubId/setting/members
          GoRoute(
            path: 'members',
            pageBuilder: (context, state) {
              final clubId = int.parse(state.pathParameters['clubId']!);
              final extra = state.extra as Map<String, dynamic>?;
              final isAdmin = (extra?['isAdmin'] as bool?) ?? false;

              return NoTransitionPage(
                key: state.pageKey,
                child: MemberListPage(
                  clubId: clubId,
                  isAdmin: isAdmin,
                ),
              );
            },
          ),
        ],
      ),
    ],
  ),
];