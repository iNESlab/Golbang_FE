import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/models/user_account.dart';
import '../../pages/common/privacy_policy_page.dart';
import '../../pages/profile/statistics_page.dart';
import '../../pages/profile/user_info_page.dart';

final List<GoRoute> userRoutes = [
  // /app/user/profile
  GoRoute(
    path: '/app/user/profile',
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return NoTransitionPage(
        key: state.pageKey,
        child: UserInfoPage(
          initialUserAccount: extra?['userAccount'] as UserAccount,
        ),
      );
    },
  ),

  // /app/user/statistics
  GoRoute(
    path: '/app/user/statistics',
    pageBuilder: (context, state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const StatisticsPage(),
      );
    },
  ),

  // /app/user/privacy-policy
  GoRoute(
    path: '/app/user/privacy-policy',
    pageBuilder: (context, state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: const PrivacyPolicyPage(),
      );
    },
  ),
];