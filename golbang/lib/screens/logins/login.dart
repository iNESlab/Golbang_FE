import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import 'forget_password.dart';
import 'hi_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    final url = Uri.parse('http://your-server-url/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['success']) {
        // 로그인 성공 처리
        // 예: 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorDialog(responseBody['message']);
      }
    } else {
      _showErrorDialog('Login failed. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Login to access your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 32),
              TextField(
                controller: _emailController,
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
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
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
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    'Forgot Password',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Background color
                  minimumSize: Size(double.infinity, 50), // Full-width button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Row(
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
              ),
              SizedBox(height: 16),
              // Google Sign-In Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: Image.asset('assets/images/google.png', width: 24),
                label: Text('Google', style: TextStyle(color: Colors.black)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[900], backgroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // KakaoTalk Sign-In Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: Image.asset('assets/images/apple.png', width: 24),
                label: Text('카카오 로그인', style: TextStyle(color: Colors.black)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.yellow,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Naver Sign-In Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: Image.asset('assets/images/facebook.png', width: 24),
                label: Text('네이버 로그인', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HiScreen()),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
