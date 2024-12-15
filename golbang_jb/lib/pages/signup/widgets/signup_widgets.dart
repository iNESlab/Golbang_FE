import 'package:flutter/material.dart';

// ID 입력 필드 위젯
class IdField extends StatelessWidget {
  final TextEditingController controller;

  const IdField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '아이디',
        hintText: '아이디를 입력해주세요',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '아이디를 입력해주세요';
        }
        return null;
      },
    );
  }
}

// 이메일 입력 필드 위젯
class EmailField extends StatelessWidget {
  final TextEditingController controller;

  const EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '이메일',
        hintText: '이메일을 입력해주세요',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이메일을 입력해주세요';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return '유효한 이메일을 입력해주세요';
        }
        return null;
      },
    );
  }
}

// 비밀번호 입력 필드 위젯
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback toggleObscureText;

  const PasswordField({
    required this.controller,
    required this.obscureText,
    required this.toggleObscureText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: '비밀번호',
        hintText: '비밀번호를 입력해주세요',
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: toggleObscureText, // 부모에서 전달된 토글 함수 호출
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해주세요';
        }
        if (value.length < 8) {
          return '비밀번호는 8자리 이상이어야 합니다';
        }
        if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]').hasMatch(value)) {
          return '비밀번호는 숫자, 문자, 특수문자를 포함해야 합니다';
        }
        return null;
      },
    );
  }
}

class ConfirmPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool obscureText;
  final VoidCallback toggleObscureText;

  const ConfirmPasswordField({
    required this.controller,
    required this.passwordController,
    required this.obscureText,
    required this.toggleObscureText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: '비밀번호 확인',
        hintText: '비밀번호를 다시 입력해주세요',
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: toggleObscureText,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호 확인을 입력해주세요';
        }
        if (value != passwordController.text) {
          return '비밀번호가 일치하지 않습니다';
        }
        return null;
      },
    );
  }
}

// 제출 버튼 위젯
class SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        disabledBackgroundColor: Colors.grey.shade300,
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text('다음', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
