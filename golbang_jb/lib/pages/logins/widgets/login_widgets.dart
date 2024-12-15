import 'package:flutter/material.dart';
import '../forget_password.dart';

class LoginTitle extends StatelessWidget {
  const LoginTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              flex: 1, // 왼쪽 영역
              child: Align(
                alignment: Alignment.centerRight, // 왼쪽 정렬
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/images/logo-green.png'), // 이미지 설정
                ),
              ),
            ),
            const Expanded(
              flex: 2, // 가운데 영역
              child: const Center(
                child: Image(
                  image: AssetImage('assets/images/text-logo-green.png'), // 텍스트 로고 이미지 설정
                  width: 150, // 이미지 크기 조정
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              flex: 1, // 오른쪽 영역 (빈 공간)
              child: Container(), // 빈 공간
            ),
          ],
        ),
        const SizedBox(height: 16),// GOLBANG과 Login 사이의 간격 조정
        Row(
          children: [
            Text(
              'Login',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.left,
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 텍스트와 필드가 왼쪽으로 정렬되도록 설정
      children: [
        const Text(
          'Email / ID',  // 텍스트 필드 위에 고정된 라벨
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,  // 라벨 색상
          ),
        ),
        const SizedBox(height: 8), // 라벨과 텍스트 필드 사이의 공간
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            hintText: 'Email Address or your ID',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({Key? key, required this.controller}) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true; // 비밀번호 숨김 상태 초기화

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText; // 비밀번호 숨기기/보이기 상태 변경
    });
  }

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
          controller: widget.controller,
          obscureText: _obscureText, // 비밀번호 숨김 여부
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            hintText: 'Password',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: _toggleVisibility, // 보이기/숨기기 토글 기능 추가
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