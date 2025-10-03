import 'dart:io'; // 플랫폼 구분을 위해 필요
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart' as dio;
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/home/splash_screen.dart';
import 'package:golbang/pages/logins/widgets/login_widgets.dart';
import 'package:golbang/pages/logins/widgets/social_login_widgets.dart';
import 'package:golbang/services/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

import '../../global/PrivateClient.dart';
import '../../repoisitory/secure_storage.dart';

class TokenCheck extends ConsumerStatefulWidget {
  final String? message;
  const TokenCheck({super.key, this.message});

  @override
  _TokenCheckState createState() => _TokenCheckState();
}

class _TokenCheckState extends ConsumerState<TokenCheck> {
  var dioClient = PrivateClient();
  bool isTokenExpired = true; // 초기값 설정
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _checkTokenStatus(); // 비동기 작업 호출
  }

  Future<void> _checkTokenStatus() async {
    final storage = ref.read(secureStorageProvider);
    final authService = ref.read(authServiceProvider);
    final isExpired = await dioClient.isAccessTokenExpired();
    if (isExpired) {
      setState(() => isTokenExpired = true);
      isLoading = false;
      return;
    }

    // 안전하게 LOGIN_ID와 PASSWORD 확인
    log('🔍 [TokenCheck] SecureStorage에서 로그인 정보 읽기 중...');

    String? savedEmail;
    String? savedPassword;

    try {
      savedEmail = await storage.readLoginId();
    } catch (e) {
      savedEmail = null;
    }

    try {
      savedPassword = await storage.readPassword();
    } catch (e) {
      savedPassword = null;
    }

    if (savedEmail == null || savedPassword == null || savedEmail.isEmpty || savedPassword.isEmpty) {
      setState(() {
        isLoading = false;
        isTokenExpired = true;
      });
      return;
    }

    // 소셜 로그인 사용자인지 확인
    if (savedPassword == 'social_login') {
      setState(() => isTokenExpired = false);
      isLoading = false;
      return;
    }

    try {
      log('🔍 [TokenCheck] 일반 로그인 사용자 - authService.login() 호출 중...');
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final response = await authService.login(
        username: savedEmail,
        password: savedPassword,
        fcmToken: fcmToken ?? '',
      );

      if (response?.statusCode == 200) {
        await storage.saveAccessToken(response?.data['data']['access_token']);
        setState(() => isTokenExpired = false); // 성공 → Splash로 이동

      } else {
        setState(() => isTokenExpired = true); // 실패 → LoginPage로 이동
      }
    } catch (e) {
      log('[TokenCheck] 자동 로그인 실패: $e');
      setState(() => isTokenExpired = true);
    } finally {
      setState(() => isLoading = false);
    }

  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isTokenExpired) {
      return LoginPage(message: widget.message);
    }

    return const SplashScreen();
  }
}

class LoginPage extends ConsumerStatefulWidget {
  final String? message;
  const LoginPage({super.key, this.message});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _snackConsumed = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showBiometricButton = false;
  late final _savedEmail;


  @override
  void initState() {
    super.initState();
    _checkSavedCredentials(); // 로그인 정보 체크

  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      // message가 바뀐 경우에만 다시 평가
      _snackConsumed = false;
      _maybeShowSnackOnce(widget.message);
    }
  }

  void _maybeShowSnackOnce(String? msg) {
    if (_snackConsumed || msg == null) return;
    _snackConsumed = true; // 스케줄 전에 먼저 true로!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    });
  }

  Future<void> _checkSavedCredentials() async {
    final storage = ref.read(secureStorageProvider);

    try {
      _savedEmail = await storage.readLoginId();

      if (_savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = _savedEmail;
          _showBiometricButton = true;
        });
      }
    } catch (e) {
      log('[LoginPage] LOGIN_ID 읽기 실패: $e');
      _savedEmail = '';
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true, bottom: true,
        child: Center(
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
                const SizedBox(height: 48),
                LoginButton(onPressed: _login),
                const SizedBox(height: 16),
                if (_showBiometricButton)
                  ElevatedButton.icon(
                    onPressed: _loginWithBiometrics,
                    icon: const Icon(Icons.fingerprint,
                      color: Colors.white,
                    ),
                    label: const Text('지문 인식',
                      style:TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                const SizedBox(height: 32),
                const SignInDivider(),
                const SizedBox(height: 16),
                const SocialLoginButtons(),
              ],
            ),
          ),
        ),
      ),
      // ✅ 하단 고정
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          // 키보드가 올라오면 여백을 자동 확장
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom
                : 16,
          ),
          child: SignUpLink(parentContext: context),
        ),
      ),
    );
  }
  Future<void> _loginWithBiometrics() async {
    final auth = LocalAuthentication();
    final canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    log('생체인증 사용 여부: ${!canAuthenticate}');

    if (!canAuthenticate) {
      _showErrorDialog('이 기기에서는 생체 인증을 사용할 수 없습니다.');
      return;
    }

    try {
      final authenticated = await auth.authenticate(
        localizedReason: '생체 인증으로 로그인',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
        // 생체 인증 성공 시 처리
        final storage = ref.read(secureStorageProvider);
        final savedPassword = await storage.readPassword();

        if (savedPassword.isNotEmpty) {
          setState(() {
            _passwordController.text = savedPassword;
          });
          _login();
        } else {
          _showErrorDialog('저장된 로그인 정보가 없습니다.\n이메일과 비밀번호로 먼저 로그인해주세요.');
        }
      } else {
        _showErrorDialog('생체 인증에 실패했습니다.');
      }
    } on PlatformException catch (e) {
      if (Platform.isAndroid) {
        log('안드로이드');
        _showErrorDialog(
          '생체 인증이 등록되어 있지 않습니다.\n기기 설정에서 등록해주세요.',
          onConfirm: () {
            final settings = OpenSettingsPlus.shared;
            if (settings is OpenSettingsPlusAndroid) {
              settings.biometricEnroll(); // ✅ 지문/생체 등록 화면 열기
            } else {
              throw Exception('Platform not supported');
            }
          },
        );
      } else {
        log('iOS apple');
        _showErrorDialog('생체 인증 실패: ${e.message}');
      }
    }
  }


  Future<void> _login() async {
    final authService = ref.watch(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String? fcmToken;
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      fcmToken = await messaging.getToken();
    } catch (e) {
      log('FCM 토큰 가져오기 실패: $e');
    }

    if (_validateInputs(email, password)) {
      try {
        final response = await authService.login(
          username: email,
          password: password,
          fcmToken: fcmToken ?? '',
        );
        await _handleLoginResponse(response!, email, password);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _showErrorDialog('Please fill in all fields');
    }
  }

  bool _validateInputs(String email, String password) {
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<void> _handleLoginResponse(dio.Response<dynamic> response, String email, String password) async {
    if (response.statusCode == 200) {
      // 로그인 성공 시 이메일 저장
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공!')),
      );

      var accessToken = response.data['data']['access_token'];
      log(accessToken);

      final storage = ref.watch(secureStorageProvider);
      await storage.saveLoginId(email);
      await storage.savePassword(password);
      await storage.saveAccessToken(accessToken);
      if (mounted) {
        context.pushReplacement('/app/splash');
      }
    } else {
      _showErrorDialog('Invalid email or password');
    }
  }

  void _showErrorDialog(String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('안내'),
        content: Text(message),
        actions: [
          if (onConfirm != null)
            TextButton(
              onPressed: () {
                context.pop();
                onConfirm();
              },
              child: const Text('설정 열기'),
            ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

}