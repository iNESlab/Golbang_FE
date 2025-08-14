import 'package:go_router/go_router.dart';
import 'package:golbang/models/user_account.dart';
import '../../pages/common/privacy_policy_page.dart';
import '../../pages/profile/statistics_page.dart';
import '../../pages/profile/user_info_page.dart';

final List<GoRoute> userRoutes = [

  GoRoute(
      path: '/app/user/profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return UserInfoPage(initialUserAccount: extra?['userAccount'] as UserAccount);
      }
  ),
  GoRoute(
      path: '/app/user/statistics',
      builder: (context, state) => const StatisticsPage(),
  ),
  GoRoute(
    path: '/app/user/privacy-policy',
    builder: (context, state) =>const PrivacyPolicyPage(),
  ),
];
