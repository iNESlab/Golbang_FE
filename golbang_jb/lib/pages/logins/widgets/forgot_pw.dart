import 'package:flutter/material.dart';
import 'package:golbang/services/user_service.dart';

class ForgotPasswordDialog extends StatelessWidget {
  const ForgotPasswordDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    return AlertDialog(
      title: const Text('Forgot Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your email address to reset your password.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 팝업 닫기
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = emailController.text.trim();
            _resetPassword(context, email);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _resetPassword(BuildContext context, String email)async {
    try {
      if (email.isNotEmpty) {
        // 이메일 유효성 검사 및 처리 로직 추가
        print('Reset link sent to $email');
        var response = await UserService.resetPassword(email: email);

        if (response.statusCode == 200) {
          Navigator.of(context).pop(); // 팝업 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reset link sent to $email')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'Failed to send reset link: ${response.reasonPhrase}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email.')),
        );
      }
    } catch (e) {
      print('[ERR] 비밀번호 갱신 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 갱신 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }
}
