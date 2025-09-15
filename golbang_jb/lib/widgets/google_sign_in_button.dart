import 'package:flutter/material.dart';
import 'dart:developer';
import '../services/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final String? buttonText;
  final double? buttonHeight;
  final double? buttonWidth;

  const GoogleSignInButton({
    Key? key,
    this.onSuccess,
    this.onError,
    this.buttonText,
    this.buttonHeight,
    this.buttonWidth,
  }) : super(key: key);

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.buttonHeight ?? 50,
      width: widget.buttonWidth ?? double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () {
          // 임시로 구글 로그인 비활성화 (테스트용)
          log('🔍 구글 로그인 임시 비활성화됨');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구글 로그인이 임시로 비활성화되었습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              )
            : Image.asset(
                'assets/images/google_logo.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  // 구글 로고 이미지가 없을 경우 텍스트로 대체
                  return Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  );
                },
              ),
        label: Text(
          widget.buttonText ?? 'Google로 로그인',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      log('🔍 구글 로그인 버튼 클릭됨');
      final result = await _googleAuthService.signInWithGoogle();
      
      log('🔍 구글 로그인 결과: $result');
      
      // 로그인 성공 처리
      if (result['access_token'] != null) {
        log('✅ 액세스 토큰 획득 성공');
        // 토큰 저장 및 성공 콜백 호출
        await _saveTokens(result);
        widget.onSuccess?.call();
        
        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구글 로그인 성공!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        log('❌ 액세스 토큰이 없음');
        throw Exception('Access token not found in response');
      }
    } catch (e) {
      log('❌ 구글 로그인 에러 발생: $e');
      log('❌ 에러 타입: ${e.runtimeType}');
      
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구글 로그인 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> result) async {
    // TODO: 토큰을 안전하게 저장 (Secure Storage 사용 권장)
    // 예시: SharedPreferences나 Secure Storage에 저장
    log('Access Token: ${result['access_token']}');
    log('Refresh Token: ${result['refresh_token']}');
    
    // 여기에 실제 토큰 저장 로직 구현
    // await secureStorage.write(key: 'access_token', value: result['access_token']);
    // await secureStorage.write(key: 'refresh_token', value: result['refresh_token']);
  }
}
