import 'package:flutter/material.dart';
import 'package:golbang/pages/signup/terms_agreement_page.dart';
import 'package:golbang/pages/logins/widgets/forgot_password.dart';
import 'package:golbang/services/google_auth_service.dart';
import 'package:golbang/services/apple_auth_service.dart';
import 'package:golbang/pages/home/splash_screen.dart';
import 'package:golbang/pages/signup/additional_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart'; // 🔧 추가: GoRouter import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔧 추가: FCM 토큰용

class SignInDivider extends StatelessWidget {
  const SignInDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign-In Button (공식 가이드라인 준수)
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _handleGoogleSignIn(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.g_mobiledata,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 🍎 애플 로그인 활성화
        const SizedBox(height: 16),
        // Apple Sign-In Button (공식 가이드라인 준수)
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _handleAppleSignIn(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.apple,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign in with Apple',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final googleAuthService = GoogleAuthService();
      
      // 새 사용자 로그인 성공 시 약관 동의 페이지로 이동
      googleAuthService.onSocialLoginSuccess = (String email, String displayName, String tempUserId) {
        if (context.mounted) {
          log('🆕 새로운 사용자: 약관 동의 페이지로 이동');
          log('🔍 구글 사용자 정보: email=$email, displayName=$displayName, tempUserId=$tempUserId');
          context.push('/app/signup/terms?email=$email&displayName=$displayName&isSocialLogin=true&provider=google&tempUserId=$tempUserId');
        }
      };
      
      // 기존 사용자 발견 시 통합 옵션 제공
      googleAuthService.onExistingUserFound = (String email, String displayName, Map<String, dynamic> existingUserData) {
        if (context.mounted) {
          _showAccountIntegrationDialog(context, email, displayName, existingUserData);
        }
      };
      
      // 기존 사용자 로그인 성공 시 메인 화면으로 이동
      googleAuthService.onExistingUserLogin = (String email, String displayName) {
        if (context.mounted) {
          log('✅ 기존 사용자: 메인 화면으로 바로 이동');
          context.go('/app/splash');
        }
      };
      
      // Google 로그인 실행
      final result = await googleAuthService.signInWithGoogle();
      
      if (result != null) {
        log('🔍 구글 로그인 결과: $result');
        
        // 콜백에서 이미 처리되므로 여기서는 추가 처리하지 않음
        // 단, 로그인 성공 메시지만 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구글 로그인 성공!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 로그인 실패: $e')),
        );
      }
    }
  }
  
  Future<void> _integrateGoogleAccount(BuildContext context, String email, String displayName, Map<String, dynamic> existingUserData) async {
    try {
      // 🔧 수정: FlutterSecureStorage에서 직접 토큰 읽기
      final storage = const FlutterSecureStorage();
      
      // 저장된 ID 토큰 가져오기
      final idToken = await storage.read(key: 'GOOGLE_ID_TOKEN');
      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google 인증 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 🔧 추가: FCM 토큰 가져오기
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        log('🔔 계정 통합용 FCM 토큰 획득: ${fcmToken?.substring(0, 20)}...');
      } catch (e) {
        log('❌ 계정 통합용 FCM 토큰 획득 실패: $e');
      }
      
      log('🔍 계정 통합 시작: $email');
      log('🔑 ID 토큰 확인: ${idToken.substring(0, 20)}...');
      
      // 계정 통합 API 호출
      final response = await http.post(
        Uri.parse('${dotenv.env['API_HOST']}/api/v1/users/integrate-google-account/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'id_token': idToken,
          'display_name': displayName,
          'fcm_token': fcmToken ?? '', // 🔧 추가: FCM 토큰 전송
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // JWT 토큰 저장
        final storage = const FlutterSecureStorage();
        await storage.write(key: 'ACCESS_TOKEN', value: data['data']['access_token']);
        await storage.write(key: 'REFRESH_TOKEN', value: data['data']['refresh_token']);
        await storage.write(key: 'LOGIN_ID', value: email);
        await storage.write(key: 'PASSWORD', value: 'social_login');
        
        // 🔧 추가: 계정 통합 성공 후 저장된 Google 토큰 정리
        await storage.delete(key: 'GOOGLE_ID_TOKEN');
        log('🗑️ 계정 통합 완료 후 Google ID 토큰 제거');
        
        // 🔧 수정: context.mounted 체크 추가
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('계정 통합이 완료되었습니다! 이제 Google 로그인으로 접근할 수 있습니다.')),
          );
          
          // 메인 화면으로 이동
          context.go('/app/splash');
        }
      } else {
        throw Exception('계정 통합 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계정 통합 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      // 애플 로그인 가용성 확인
      final isAvailable = await AppleAuthService.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apple 로그인을 사용할 수 없습니다. (iOS 13+ 필요)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 애플 로그인 실행
      final result = await AppleAuthService.signInWithApple();
      
      if (result != null && result['success'] == true) {
        final loginType = result['login_type'];
        log('🔍 애플 로그인 결과: loginType=$loginType, result=$result');
        
        if (loginType == 'existing') {
          // 기존 사용자 로그인 - 메인 화면으로 바로 이동
          if (context.mounted) {
            log('✅ 기존 사용자: 메인 화면으로 바로 이동');
            context.go('/app/splash');
          }
          
        } else if (loginType == 'integration') {
          // 계정 통합 필요
          if (context.mounted) {
            final email = result['data']['existing_user_id'] ?? '';
            final displayName = result['data']['existing_user_name'] ?? '';
            log('🔍 애플 계정 통합 필요: email=$email, displayName=$displayName');
            
            _showAccountIntegrationDialog(context, email, displayName, result['data']);
          }
          
        } else if (loginType == 'new' || loginType == 'new_user') {
          // 신규 사용자 - 약관 동의 페이지로 이동
          if (context.mounted) {
            log('🆕 새로운 사용자: 약관 동의 페이지로 이동');
            
            // 애플 로그인에서는 이메일과 이름이 없을 수 있음
            final email = result['user']?['email'] ?? '';
            final displayName = result['user']?['user_name'] ?? '';
            final tempUserId = result['data']?['temp_user_id'] ?? '';
            
            log('🔍 애플 로그인 전체 응답: $result');
            log('🔍 애플 사용자 정보: email=$email, displayName=$displayName, tempUserId=$tempUserId');
            
            // 이메일이나 이름이 없으면 빈 문자열로 전달하여 사용자가 직접 입력하도록 함
            String queryParams = 'isSocialLogin=true&provider=apple';
            if (email.isNotEmpty) {
              queryParams += '&email=$email';
            }
            if (displayName.isNotEmpty) {
              queryParams += '&displayName=$displayName';
            }
            if (tempUserId.isNotEmpty) {
              queryParams += '&tempUserId=$tempUserId';
            }
            
            log('🔍 최종 쿼리 파라미터: $queryParams');
            context.push('/app/signup/terms?$queryParams');
          }
          
        } else if (loginType == 'integration') {
          // 계정 통합 필요
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('계정 통합이 필요합니다: ${result['message']}'),
                backgroundColor: Colors.orange,
              ),
            );
            // TODO: 계정 통합 다이얼로그 표시
          }
        } else {
          // 알 수 없는 login_type
          log('❌ 알 수 없는 login_type: $loginType');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('알 수 없는 로그인 타입: $loginType'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        
      } else {
        // 로그인 실패
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('애플 로그인 실패: ${result?['message'] ?? '알 수 없는 오류'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple 로그인 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showAccountIntegrationDialog(BuildContext context, String email, String displayName, Map<String, dynamic> existingUserData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('계정 통합'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이미 가입된 이메일입니다: $email'),
              const SizedBox(height: 8),
              Text('기존 계정: ${existingUserData['existing_user_name']}'),
              Text('로그인 방식: ${existingUserData['login_type']}'),
              if (existingUserData['provider'] != null && existingUserData['provider'] != 'none')
                Text('제공자: ${existingUserData['provider']}'),
              const SizedBox(height: 16),
              const Text('이 계정을 Google 계정과 통합하시겠습니까?'),
              const SizedBox(height: 8),
              const Text('통합하면 Google 로그인과 일반 로그인 모두로 기존 계정에 접근할 수 있습니다.', 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('계정 통합을 취소했습니다.')),
                );
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _integrateGoogleAccount(context, email, displayName, existingUserData);
              },
              child: const Text('통합하기'),
            ),
          ],
        );
      },
    );
  }
}

class SignUpLink extends StatelessWidget {
  final BuildContext parentContext;
  const SignUpLink({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "계정이 없으신가요? ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            GestureDetector(
              onTap: () => context.push('/app/signup/terms'),
              child: const Text(
                '회원가입',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // 원하는 간격 조정
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "비밀번호를 잊으셨나요?  ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            GestureDetector(
              onTap: () async {
                // showDialog로 다이얼로그 띄우기
                await showDialog(
                  context: context,
                  builder: (_) => ForgotPasswordDialog(parentContext: parentContext)
                );
              },
              child: const Text(
                '비밀번호 초기화',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ]
    );
  }
}