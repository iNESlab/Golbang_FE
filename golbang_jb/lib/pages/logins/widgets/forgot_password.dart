import 'package:flutter/material.dart';
import 'package:golbang/services/user_service.dart';

class ForgotPasswordDialog extends StatelessWidget {
  const ForgotPasswordDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    return AlertDialog(
      title: const Text('비밀번호 재발급'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '로그인 이메일을 적어주시면,\n해당 메일로 비밀번호를 재발급해드립니다..',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'email',
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
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = emailController.text.trim();
            _resetPassword(context, email);
          },
          child: const Text('완료'),
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
            SnackBar(content: Text('적어주신 $email 로 전송되었습니다')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                '전송 실패했습니다: ${response.reasonPhrase}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효한 이메일이 아닙니다.')),
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
