import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../global/PrivateClient.dart';
import '../global/PublicClient.dart';
import '../models/user.dart';

class AppleAuthService {
  static final String _baseUrl = dotenv.env['API_HOST']!;

  /// 애플 로그인 실행
  static Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      log('🍎 애플 로그인 시작');

      // 애플 로그인 요청
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      log('🍎 애플 로그인 성공: ${credential.userIdentifier}');

      // 백엔드에 토큰 전송
      final result = await _sendTokenToBackend(
        identityToken: credential.identityToken!,
        userIdentifier: credential.userIdentifier!,
        email: credential.email,
        fullName: credential.givenName != null && credential.familyName != null
            ? '${credential.givenName} ${credential.familyName}'
            : null,
      );

      return result;
    } on SignInWithAppleAuthorizationException catch (e) {
      log('❌ 애플 로그인 취소 또는 오류: ${e.code}');
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          log('사용자가 로그인을 취소했습니다');
          return null;
        case AuthorizationErrorCode.failed:
          log('로그인 실패');
          return null;
        case AuthorizationErrorCode.invalidResponse:
          log('잘못된 응답');
          return null;
        case AuthorizationErrorCode.notHandled:
          log('처리되지 않은 오류');
          return null;
        case AuthorizationErrorCode.notInteractive:
          log('인터랙티브하지 않은 환경에서 로그인 시도');
          return null;
        case AuthorizationErrorCode.unknown:
          log('알 수 없는 오류');
          return null;
      }
    } catch (e) {
      log('❌ 애플 로그인 예외: $e');
      return null;
    }
  }

  /// 백엔드에 애플 토큰 전송
  static Future<Map<String, dynamic>?> _sendTokenToBackend({
    required String identityToken,
    required String userIdentifier,
    String? email,
    String? fullName,
  }) async {
    try {
      // 🔧 추가: FCM 토큰 가져오기
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        log('🔔 FCM 토큰 획득: ${fcmToken?.substring(0, 20)}...');
      } catch (e) {
        log('❌ FCM 토큰 획득 실패: $e');
      }
      
      final publicClient = PublicClient();
      
      final response = await publicClient.dio.post(
        '/api/v1/users/apple-login-mobile/',
        data: {
          'identity_token': identityToken,
          'user_identifier': userIdentifier,
          'email': email,
          'full_name': fullName ?? '애플 사용자',
          'fcm_token': fcmToken ?? '', // 🔧 추가: FCM 토큰 전송
        },
      );

      log('🍎 백엔드 응답: ${response.statusCode}');
      log('🍎 백엔드 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 200) {
          // JWT 토큰 저장 (기존 사용자)
          if (data['data']['access_token'] != null) {
            final storage = const FlutterSecureStorage();
            await storage.write(key: 'ACCESS_TOKEN', value: data['data']['access_token']);
            if (data['data']['refresh_token'] != null) {
              await storage.write(key: 'REFRESH_TOKEN', value: data['data']['refresh_token']);
            }
            await storage.write(key: 'LOGIN_ID', value: email ?? 'apple_user');
            await storage.write(key: 'PASSWORD', value: 'social_login');
            log('💾 애플 로그인 토큰 저장 완료 (기존 사용자)');
          }
          
          return {
            'success': true,
            'login_type': 'existing',  // 기존 사용자
            'access_token': data['data']['access_token'],
            'refresh_token': data['data']['refresh_token'],
            'user': data['data'],
            'message': data['message'],
          };
        } else {
          log('❌ 백엔드 오류: ${data['message']}');
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else if (response.statusCode == 201) {
        final data = response.data;
        
        // JWT 토큰 저장 (새 사용자)
        if (data['data']['access_token'] != null) {
          final storage = const FlutterSecureStorage();
          await storage.write(key: 'ACCESS_TOKEN', value: data['data']['access_token']);
          if (data['data']['refresh_token'] != null) {
            await storage.write(key: 'REFRESH_TOKEN', value: data['data']['refresh_token']);
          }
          await storage.write(key: 'LOGIN_ID', value: email ?? 'apple_user');
          await storage.write(key: 'PASSWORD', value: 'social_login');
          log('💾 애플 로그인 토큰 저장 완료');
        }
        
        return {
          'success': true,
          'login_type': 'new',  // 신규 사용자
          'access_token': data['data']['access_token'],
          'refresh_token': data['data']['refresh_token'],
          'user': data['data'],
          'message': data['message'],
        };
      } else if (response.statusCode == 226) {
        final data = response.data;
        
        // 226: 추가 정보 입력 필요 (신규 사용자)
        if (data['data']?['requires_additional_info'] == true) {
          return {
            'success': true,
            'login_type': 'new_user',  // 신규 사용자 - 추가 정보 입력 필요
            'status': 226,  // 🔧 추가: status 필드 명시
            'message': data['message'],
            'data': data['data'],
            'user': {  // 🔧 추가: user 정보도 포함
              'email': data['data']['email'],
              'user_name': data['data']['display_name'],
            },
          };
        } else {
          // 226: 계정 통합 필요
          return {
            'success': true,
            'login_type': 'integration',  // 계정 통합 필요
            'message': data['message'],
            'data': data['data'],
          };
        }
      } else {
        log('❌ HTTP 오류: ${response.statusCode}');
        return {
          'success': false,
          'message': '서버 오류가 발생했습니다',
        };
      }
    } catch (e) {
      log('❌ 백엔드 통신 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다',
      };
    }
  }

  /// 애플 로그인 가능 여부 확인 (iOS 13+)
  static Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      log('❌ 애플 로그인 가용성 확인 실패: $e');
      return false;
    }
  }
}
