import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/signup/widgets/welcome_header_widget.dart';
import '../../provider/user/user_service_provider.dart';
import 'widgets/signup_widgets.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();


  bool _obscurePassword = true; // 비밀번호(확인) 필드 숨김 상태

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        // 기기 화면 크기에 맞춰 동적으로 배치
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double padding = constraints.maxWidth * 0.08;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                children: [
                  // 1) 중앙 영역(폼)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 웰컴 헤더
                              const WelcomeHeader(topPadding: 0.1),
                              // 회원가입 필드
                              IdField(controller: _idController),
                              const SizedBox(height: 16.0),
                              EmailField(controller: _emailController),
                              const SizedBox(height: 16.0),
                              PasswordField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                toggleObscureText: _togglePasswordVisibility,
                              ),
                              const SizedBox(height: 16.0),
                              ConfirmPasswordField(
                                controller: _confirmPasswordController,
                                passwordController: _passwordController,
                                obscureText: _obscurePassword,
                                toggleObscureText: _togglePasswordVisibility,
                              ),
                              const SizedBox(height: 26.0),
                              // 여기서 SubmitButton을 빼고,
                              // 버튼을 아래(2) 영역에서 고정 배치
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 2) 하단 버튼 (고정)
                  SubmitButton(onPressed: () => _signupStep1(context)),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _signupStep1(BuildContext ctx) async {
    final userService = ref.watch(userServiceProvider);

    if (_formKey.currentState!.validate()) {
      log('_idController.text: ${_idController.text}');
      log('_emailController.text: ${_emailController.text}');
      log('_passwordController.text: ${_passwordController.text}');

      try {
        var response = await userService.saveUser(
          userId: _idController.text,
          email: _emailController.text,
          password1: _passwordController.text,
          password2: _confirmPasswordController.text,
        );

        if (response.statusCode == 201) {
          ctx.push('/app/signup/step-2', extra: {'userId': response.data['data']['user_id'] });
        } else {
          var error = response.data['data']?['message'] ?? '알 수 없는 오류가 발생했습니다.';

          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('\n회원가입에 실패했습니다. 다시 시도해 주세요. $error'),
            ),
          );
        }
      } catch (e) {
        log('Error: $e');
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }
}
