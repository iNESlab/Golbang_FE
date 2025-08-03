import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/provider/user/user_service_provider.dart';

class ForgotPasswordDialog extends ConsumerWidget {
  final BuildContext parentContext;
  const ForgotPasswordDialog({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onPressed: () => context.pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = emailController.text.trim();
            _resetPassword(context, ref, email);
          },
          child: const Text('완료'),
        ),
      ],
    );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref, String email)async {
    final messenger = ScaffoldMessenger.of(parentContext); // 먼저 저장

    try {
      final userService = ref.watch(userServiceProvider);

      if (email.isNotEmpty) {
        // 이메일 유효성 검사 및 처리 로직 추가
        log('Reset link sent to $email');
        var response = await userService.resetPassword(email: email);

        if (response.statusCode == 200) {
          messenger.showSnackBar(
            SnackBar(content: Text('$email로 전송되었습니다')),
          );
          context.pop();
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text('전송 실패했습니다: ${response.data['message']}')),
          );
        }

      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('유효한 이메일이 아닙니다.')),
        );
      }
    } on DioException catch (e) {
      log('[ERR] 비밀번호 갱신 실패: $e');
      final message = e.response?.data['message'] ?? '알 수 없는 에러입니다.';
      messenger.showSnackBar(
        SnackBar(content: Text('$message')),
      );
    }
  }
}
