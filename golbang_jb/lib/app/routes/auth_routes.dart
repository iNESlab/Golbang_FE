import 'package:go_router/go_router.dart';

import '../../pages/common/privacy_policy_page.dart';
import '../../pages/logins/login.dart';
import '../../pages/signup/additional_info.dart';
import '../../pages/signup/marketing_agreement_page.dart';
import '../../pages/signup/signup.dart';
import '../../pages/signup/signup_complete.dart';
import '../../pages/signup/term_of_service_page.dart';
import '../../pages/signup/terms_agreement_page.dart';

final List<GoRoute> authRoutes = [

  GoRoute(
      path: '/app',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TokenCheck(message: extra?['message'],);
      } // 로그인 여부 체크 후 리디렉션 처리
  ),
  GoRoute(
    path: '/app/signup',
    builder: (context, state) => const SignUpPage(),
    routes: [
      GoRoute(
      path: 'step-2',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdditionalInfoPage(userId: extra?['userId'] as int,);
        },
      ),
      GoRoute(
        path: 'terms',
        builder: (context, state) {
          return const TermsAgreementPage();
        },
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final key = extra?['key'] as String;
              // 약관 항목에 따라 이동할 페이지 설정
              if (key == '[필수] 이용약관 동의') {
                return const TermsOfServicePage(); // 이용약관 페이지 연결
              } else if (key == '[필수] 개인정보 수집 및 이용 동의') {
                return  const PrivacyPolicyPage(); // 개인정보처리방침 페이지 연결
              } else {
               return  const MarketingAgreementPage(); // 광고성 정보 수신 동의 페이지 연결
              }
            }
          ),
        ]
      ),
      GoRoute(
        path: 'complete',
        builder: (context, state) => const SignupComplete(),
      ),
    ]
  ),
  GoRoute(
      path: '/app/login',
      builder: (context, state) => const LoginPage(),
  ),

];
