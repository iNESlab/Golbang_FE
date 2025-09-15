import 'package:flutter/material.dart';
import 'package:golbang/pages/signup/terms_agreement_page.dart';
import 'package:golbang/pages/logins/widgets/forgot_password.dart';
import 'package:golbang/services/google_auth_service.dart';
import 'package:golbang/pages/home/splash_screen.dart';
import 'package:golbang/pages/signup/additional_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart'; // 🔧 추가: GoRouter import
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
                    Image.asset(
                      'assets/images/google.webp',
                      width: 20,
                      height: 20,
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
        // 🚫 애플 로그인 비활성화 - 구글 로그인만 사용
        // const SizedBox(height: 16),
        // // Apple Sign-In Button (공식 가이드라인 준수)
        // Container(
        //   width: double.infinity,
        //   height: 48,
        //   decoration: BoxDecoration(
        //     color: Colors.black,
        //     borderRadius: BorderRadius.circular(8),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.2),
        //         blurRadius: 4,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //   child: Material(
        //     color: Colors.transparent,
        //     child: InkWell(
        //       borderRadius: BorderRadius.circular(8),
        //       onTap: () => _handleAppleSignIn(context),
        //       child: Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: 16),
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             Image.asset(
        //               'assets/images/apple.webp',
        //               width: 20,
        //               height: 20,
        //               color: Colors.white,
        //             ),
        //             const SizedBox(width: 12),
        //             const Text(
        //               'Sign in with Apple',
        //               style: TextStyle(
        //                 color: Colors.white,
        //                 fontSize: 16,
        //                 fontWeight: FontWeight.w500,
        //                 fontFamily: 'SF Pro Display',
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final googleAuthService = GoogleAuthService();
      
      // 소셜 로그인 성공 후 화면 전환을 위한 콜백 설정
      googleAuthService.onSocialLoginSuccess = (String email, String displayName) {
        if (context.mounted) {
          // 🔧 수정: 기존 사용자와 새 사용자 구분
          final storage = const FlutterSecureStorage();
          storage.read(key: 'ACCESS_TOKEN').then((token) {
            if (token != null) {
              // JWT 토큰이 있으면 기존 사용자 → 메인 화면으로 바로 이동
              log('✅ 기존 사용자: 메인 화면으로 바로 이동');
              context.go('/app/splash');
            } else {
              // JWT 토큰이 없으면 새로운 사용자 → 약관 동의 페이지로 이동
              log('🆕 새로운 사용자: 약관 동의 페이지로 이동');
              context.push('/app/signup/terms?email=$email&displayName=$displayName&isSocialLogin=true');
            }
          });
        }
      };
      
      // 기존 사용자 발견 시 통합 옵션 제공
      googleAuthService.onExistingUserFound = (String email, String displayName, Map<String, dynamic> existingUserData) {
        if (context.mounted) {
          _showAccountIntegrationDialog(context, email, displayName, existingUserData);
        }
      };
      
      final result = await googleAuthService.signInWithGoogle();
      
      if (result != null) {
        // 로그인 성공 시 처리
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계정 통합이 완료되었습니다! 이제 Google 로그인으로 접근할 수 있습니다.')),
        );
        
        // 🔧 수정: GoRouter 사용으로 Navigator API 충돌 방지
        // 메인 화면으로 이동
        context.go('/app/splash');
      } else {
        throw Exception('계정 통합 실패: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계정 통합 중 오류가 발생했습니다: $e')),
      );
    }
  }
  
  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      // TODO: Apple Sign-In 구현
      // Apple Sign-In은 iOS 13+에서만 지원되므로 플랫폼 체크 필요
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple 로그인은 준비 중입니다.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple 로그인 실패: $e')),
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
              if (existingUserData['provider'] != null)
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