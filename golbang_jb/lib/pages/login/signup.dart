import 'package:flutter/material.dart';
import 'additional_info.dart';
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  // TextEditingController에 초기값 설정
  final _idController = TextEditingController(text: 'testID'); // 예시 아이디
  final _emailController = TextEditingController(text: 'test@example.com'); // 예시 이메일
  final _passwordController = TextEditingController(text: 'password123!'); // 예시 비밀번호
  final _confirmPasswordController = TextEditingController(text: 'password123!'); // 예시 비밀번호 확인

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '회원가입',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _idController,
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
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
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
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력해주세요',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordController.text.isNotEmpty ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          // Toggle password visibility
                        });
                      },
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
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호를 다시 입력해주세요',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordController.text.isNotEmpty ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          // Toggle confirm password visibility
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호 확인을 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // AdditionalInfoPage로 이동
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AdditionalInfoPage(
                            name: "test",
                            phoneNumber: "01000000000",
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // 버튼을 가로로 크게 설정
                  ),
                  child: Text('다음'),
                ),
                SizedBox(height: 16.0),
                Center(child: Text('Or Register with')),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialLoginButton('assets/images/google.png', () {
                      // 구글 로그인 로직을 수행합니다.
                    }),
                    _buildSocialLoginButton('assets/images/kakao.png', () {
                      // 카카오 로그인 로직을 수행합니다.
                    }),
                    _buildSocialLoginButton('assets/images/naver.png', () {
                      // 네이버 로그인 로직을 수행합니다.
                    }),
                  ],
                ),
                SizedBox(height: 16.0),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // 로그인 페이지로 이동하는 로직을 수행합니다.
                    },
                    child: Text(
                      '이미 계정이 있으신가요? Login Now',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Image.asset(
          assetPath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}