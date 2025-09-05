import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../provider/user/user_service_provider.dart';

class ForgotPasswordDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const ForgotPasswordDialog({super.key, required this.parentContext});

  @override
  ConsumerState<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final TextEditingController emailController = TextEditingController();
  bool _isButtonDisabled = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('비밀번호 재발급'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '로그인 이메일을 적어주시면,\n해당 메일로 비밀번호를 재발급해드립니다.',
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
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isButtonDisabled
              ? null
              : () async {
            setState(() => _isButtonDisabled = true);
            await _resetPassword(context, emailController.text.trim());
            // 2초 후 버튼 다시 활성화
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) setState(() => _isButtonDisabled = false);
            });
          },
          child: const Text('완료'),
        ),
      ],
    );
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(widget.parentContext);

    try {
      final userService = ref.read(userServiceProvider);

      if (email.isNotEmpty) {
        var response = await userService.resetPassword(email: email);

        if (response.statusCode == 200) {
          messenger.showSnackBar(
            SnackBar(content: Text('$email로 전송되었습니다')),
          );
          context.pop();
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }
}