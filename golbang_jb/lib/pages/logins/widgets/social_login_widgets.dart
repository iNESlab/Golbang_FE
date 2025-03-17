import 'package:flutter/material.dart';
import 'package:golbang/pages/signup/terms_agreement_page.dart';
import 'package:golbang/pages/logins/widgets/forgot_password.dart';


class SignInDivider extends StatelessWidget {
  const SignInDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[700],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Or Sign In With',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[700],
            thickness: 1,
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
        OutlinedButton.icon(
          onPressed: () {},
          icon: Image.asset('assets/images/google.webp', width: 24),
          label: const Text('Google', style: TextStyle(color: Colors.black)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[900],
            backgroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: Image.asset('assets/images/kakao.webp', width: 24),
          label:
          const Text('카카오 로그인', style: TextStyle(color: Colors.black)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.yellow,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: Image.asset('assets/images/naver.webp', width: 24),
          label:
          const Text('네이버 로그인', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ],
    );
  }
}

class SignUpLink extends StatelessWidget {
  const SignUpLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "계정이 없으신가요? ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsAgreementPage()),
                );
              },
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
              onTap: () {
                // showDialog로 다이얼로그 띄우기
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const ForgotPasswordDialog();
                  },
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