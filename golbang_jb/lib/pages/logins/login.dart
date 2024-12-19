import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:golbang/pages/home/splash_screen.dart';
import 'package:golbang/pages/logins/widgets/login_widgets.dart';
import 'package:golbang/pages/logins/widgets/social_login_widgets.dart';
import 'package:golbang/services/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../repoisitory/secure_storage.dart';

class TokenCheck extends ConsumerStatefulWidget {
  const TokenCheck({super.key});

  @override
  _TokenCheckState createState() => _TokenCheckState();
}

class _TokenCheckState extends ConsumerState<TokenCheck> {
  bool isToken = false;

  @override
  void initState() {
    super.initState();
    _autoLoginCheck();
  }

  Future<void> _autoLoginCheck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isAutoLoginEnabled = prefs.getBool('isAutoLoginEnabled') ?? true;
    if (isAutoLoginEnabled) {
      // `ref.read`로 AuthService 인스턴스 가져오기
      final authService = ref.read(authServiceProvider);

      try {
        final response = await authService.validateToken();
        if (response.statusCode == 202) {
          setState(() {
            isToken = true; // 유효한 토큰
          });
        } else {
          setState(() {
            isToken = false; // 무효한 토큰
          });
          // 무효한 토큰 삭제
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
        }
      } catch (e) {
        setState(() {
          isToken = false; // 네트워크 오류 등
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isToken ? const SplashScreen() : const LoginPage(),
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text: 'Kojungbeom');
  final TextEditingController _passwordController = TextEditingController(text: 'Golbang12!@!');
  bool _isAutoLoginEnabled = false;

  // 저장된 이메일 불러오기
  Future<void> _loadSavedEmail() async {
    try {
      final storage = ref.read(secureStorageProvider); // SecureStorage 인스턴스 가져오기
      final savedEmail = await storage.readLoginId(); // 로그인 ID 불러오기

      if (savedEmail != null) {
        setState(() {
          _emailController.text = savedEmail; // 이메일 필드에 자동완성
        });
      }
    } catch (e) {
      print('이메일 불러오기 실패: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedEmail(); // 앱 실행 시 저장된 이메일 불러오기
  }

  Future<void> _setAutoLogin(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoLoginEnabled', true); // 설정 저장
    await prefs.setString('token', token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoginTitle(),
              const SizedBox(height: 32),
              EmailField(controller: _emailController),
              const SizedBox(height: 16),
              PasswordField(controller: _passwordController),
              const SizedBox(height: 64),
              LoginButton(onPressed: _login),
              const SizedBox(height: 48),
              const SignUpLink() ,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String? fcmToken;
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      fcmToken = await messaging.getToken();
    } catch (e) {
      print('FCM 토큰 가져오기 실패: $e');
    }

    if (_validateInputs(email, password)) {
      try {
        final response = await AuthService.login(
          username: email,
          password: password,
          fcm_token: fcmToken ?? '',
        );
        await _handleLoginResponse(response, email);
      } catch (e) {
        _showErrorDialog('An error occurred. Please try again.');
      }
    } else {
      _showErrorDialog('Please fill in all fields');
    }
  }

  bool _validateInputs(String email, String password) {
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<void> _handleLoginResponse(http.Response response, String email) async {
    if (response.statusCode == 200) {
      // 로그인 성공 시 이메일 저장
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공!')),
      );

      final body = json.decode(response.body);
      var accessToken = body['data']['access_token'];
      await _setAutoLogin(accessToken);

      final storage = ref.watch(secureStorageProvider);
      await storage.saveLoginId(email);
      await storage.saveAccessToken(accessToken);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    } else {
      _showErrorDialog('Invalid email or password');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}