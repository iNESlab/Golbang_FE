import 'package:go_router/go_router.dart';
import 'package:golbang/models/user_account.dart';
import '../../pages/common/privacy_policy_page.dart';
import '../../pages/profile/user_info_page.dart';

final List<GoRoute> userRoutes = [

  GoRoute(
      path: 'user/profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return UserInfoPage(initialUserAccount: extra?['userAccount'] as UserAccount);
      }
  ),
  GoRoute(
      path: '/user/statistics',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return UserInfoPage(initialUserAccount: extra?['userAccount'] as UserAccount);
      }
  ),
  GoRoute(
    path: '/user/privacy-policy',
    builder: (context, state) {
      return const PrivacyPolicyPage();
    },
  ),
];
