import 'package:flutter/material.dart';
import '../forget_password.dart';

class LoginTitle extends StatelessWidget {
  const LoginTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬을 위한 설정
      children: [
        const SizedBox(height: 20),  // GOLBANG 텍스트를 더 위로 보내기 위해 높이 줄임
        const Center(  // GOLBANG 텍스트는 가운데에 위치
          child: Text(
            'GOLBANG',
            style: TextStyle(
              fontSize: 48,  // 텍스트 크기를 더 크게 설정
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),  // GOLBANG과 Login 사이의 간격 조정
        Align(  // Login 텍스트를 왼쪽 끝에 정렬하기 위해 사용
          alignment: Alignment.centerLeft,
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 24,  // Login 텍스트 크기를 조금 줄임
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  const EmailField({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[800],
        hintText: 'Email Address',
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  const PasswordField({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 라벨과 필드가 왼쪽 정렬되도록 설정
      children: [
        const Text(
          'Password',  // 텍스트 필드 위에 고정된 라벨
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,  // 라벨 색상 설정
          ),
        ),
        const SizedBox(height: 8), // 라벨과 텍스트 필드 사이의 간격
        TextField(
          controller: controller,
          obscureText: true, // 비밀번호를 가리도록 설정
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            hintText: 'Password',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Icon(
              Icons.visibility_off,
              color: Colors.grey[500],
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}


class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ForgotPasswordPage()),
          );
        },
        child: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  const LoginButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal, // Background color
        minimumSize: const Size(double.infinity, 50), // Full-width button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      child: const Text(
        'Login',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }
}