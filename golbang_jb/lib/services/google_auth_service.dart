import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class GoogleAuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // 백엔드 URL (환경변수 사용)
  String get _backendUrl => '${dotenv.env['API_HOST']}/api/v1/users/google-login-mobile/';

  static const String _androidClientId = '1032223675274-3moln20qdn5umb2cqj8qaps5t0jbgq42.apps.googleusercontent.com';
  static const String _iosClientId = '1032223675274-rrr118a333crcgnm2d6fbtkm16a0ee3r.apps.googleusercontent.com';
  
  // 소셜 로그인 성공 후 화면 전환을 위한 콜백
  Function(String email, String displayName)? onSocialLoginSuccess;
  
  // 기존 사용자 통합 옵션을 위한 콜백
  Function(String email, String displayName, Map<String, dynamic> existingUserData)? onExistingUserFound;
  
  // 🔧 추가: 현재 Google 로그인 정보 저장
  GoogleSignInAccount? _currentGoogleUser;
  String? _currentIdToken;


  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      log('🔍 Google Sign-In 시작...');
      
      // 공식 문서 방식: instance 사용
      final GoogleSignIn signIn = GoogleSignIn.instance;
      
      // 🔧 추가: 이전 로그인 정보 초기화
      log('🔧 이전 로그인 정보 초기화 중...');
      await signIn.signOut();
      await signIn.disconnect();
      
      // 플랫폼별 클라이언트 ID 선택
      String clientId;
      if (Platform.isAndroid) {
        clientId = _androidClientId;
        log('🤖 Android 플랫폼 감지 - Android 클라이언트 ID 사용');
      } else if (Platform.isIOS) {
        clientId = _iosClientId;
        log('🍎 iOS 플랫폼 감지 - iOS 클라이언트 ID 사용');
      } else {
        clientId = _androidClientId; // 기본값
        log('⚠️ 알 수 없는 플랫폼 - Android 클라이언트 ID 사용 (기본값)');
      }
      
      // initialize로 초기화
      log('🔧 GoogleSignIn 초기화 중...');
      log('🔑 사용할 클라이언트 ID: $clientId');
      log('🔍 현재 플랫폼: ${Platform.operatingSystem}');
      log('🔍 Android 클라이언트 ID: $_androidClientId');
      log('🔍 iOS 클라이언트 ID: $_iosClientId');
      
      await signIn.initialize(
        clientId: clientId,
      );
      log('✅ GoogleSignIn 초기화 완료');
      
      // Google Sign-In 실행 (authenticate 사용)
      final GoogleSignInAccount? googleUser = await signIn.authenticate();
      
      if (googleUser == null) {
        log('❌ 사용자가 Google Sign-In을 취소했습니다.');
        throw Exception('Google Sign-In cancelled');
      }

      log('✅ Google Sign-In 성공: ${googleUser.email}');
      log('🔍 사용자 ID: ${googleUser.id}');
      log('🔍 사용자 이름: ${googleUser.displayName}');
      
      // ID 토큰 사용 (간단하고 효율적)
      log('🔍 ID 토큰 가져오는 중...');
      
      final GoogleSignInAuthentication auth = await googleUser.authentication;
      
      if (auth.idToken != null) {
        log('🔑 ID 토큰 획득: ${auth.idToken?.substring(0, 20) ?? 'null'}...');
        
        // 🔧 추가: 현재 로그인 정보 저장
        _currentGoogleUser = googleUser;
        _currentIdToken = auth.idToken;
        
        // 🔧 추가: ID 토큰을 FlutterSecureStorage에 저장
        await _storage.write(key: 'GOOGLE_ID_TOKEN', value: auth.idToken);
        log('💾 Google ID 토큰 저장 완료: ${auth.idToken?.substring(0, 20) ?? 'null'}...');
        
        // ID 토큰을 백엔드로 전송 (사용자 정보도 함께 전달)
        final response = await _sendIdTokenToBackend(
          auth.idToken!, // 이미 null check를 했으므로 안전함
          googleUser.email, 
          googleUser.displayName
        );
        log('✅ 백엔드 응답 성공: ${response['status']}');
        return response;
      } else {
        log('❌ ID 토큰을 가져올 수 없습니다.');
        throw Exception('Failed to get ID token');
      }
      
    } catch (e) {
      log('❌ Google Sign-In 에러: $e');
      log('❌ 에러 타입: ${e.runtimeType}');
      if (e is Exception) {
        log('❌ Exception 상세: ${e.toString()}');
      }
      
      // 🔧 추가: 특정 에러에 대한 처리
      if (e.toString().contains('Account reauth failed')) {
        log('💡 해결 방법:');
        log('1. Google 계정에서 앱 권한을 제거하고 다시 시도하세요');
        log('2. 다른 Google 계정으로 로그인해보세요');
        log('3. 기기에서 Google 계정을 다시 추가해보세요');
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _sendAuthCodeToBackend(String authCode) async {
    try {
      log('🌐 백엔드로 Auth Code 전송 중...');
      log('📍 백엔드 URL: $_backendUrl');
      
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'auth_code': authCode,
        }),
      );

      log('📡 백엔드 응답 상태: ${response.statusCode}');
      log('📡 백엔드 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ 백엔드 응답 파싱 성공');
        return data;
      } else {
        log('❌ 백엔드 에러: ${response.statusCode}');
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ 백엔드 통신 에러: $e');
      rethrow;
    }
  }

  // 🔧 추가: 저장된 토큰 재사용 메서드
  String? getCurrentIdToken() {
    return _currentIdToken;
  }
  
  GoogleSignInAccount? getCurrentGoogleUser() {
    return _currentGoogleUser;
  }
  
  // 🔧 추가: 토큰 초기화 메서드
  void clearStoredTokens() {
    _currentGoogleUser = null;
    _currentIdToken = null;
    
    // 🔧 추가: FlutterSecureStorage에서도 Google 토큰 제거
    _storage.delete(key: 'GOOGLE_ID_TOKEN');
    log('🗑️ Google ID 토큰 제거 완료');
  }

  Future<Map<String, dynamic>> _sendIdTokenToBackend(
    String idToken, 
    String email, 
    String? displayName
  ) async {
    try {
      log('🌐 백엔드로 ID 토큰 전송 중...');
      
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
          'email': email,
          'display_name': displayName ?? 'Unknown',
        }),
      );

      // 200(OK)과 201(Created) 모두 성공으로 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        log('✅ 백엔드 응답 성공: ${response.statusCode}');
          
          // 🔧 수정: 통합 상태에 따른 처리
          if (data['data']?['user_exists'] == true && data['data']?['needs_integration'] == true) {
            // 기존 사용자이지만 통합이 필요한 경우 통합 옵션 제공
            log('🔍 기존 사용자 발견 (통합 필요): ${data['data']['existing_user_name']}');
            if (onExistingUserFound != null) {
              onExistingUserFound!(email, displayName ?? 'Unknown', data['data']);
            }
            return data;
          } else if (data['data']?['user_exists'] == true && data['data']?['needs_integration'] != true) {
            // 기존 사용자이고 이미 통합된 경우 바로 로그인 성공
            log('✅ 기존 사용자 (이미 통합됨): 바로 로그인 성공');
            
            // JWT 토큰 저장
            if (data['data']['access_token'] != null) {
              await _storage.write(key: 'ACCESS_TOKEN', value: data['data']['access_token']);
              if (data['data']['refresh_token'] != null) {
                await _storage.write(key: 'REFRESH_TOKEN', value: data['data']['refresh_token']);
              }
              await _storage.write(key: 'LOGIN_ID', value: email);
              await _storage.write(key: 'PASSWORD', value: 'social_login');
            }
            
            if (onSocialLoginSuccess != null) {
              onSocialLoginSuccess!(email, displayName ?? 'Unknown');
            }
            return data;
          } else if (data['data']?['user_exists'] == false && data['data']?['access_token'] != null) {
            // 새로운 사용자인 경우 JWT 토큰 저장 및 화면 전환
            log('✅ 새 사용자: 약관 동의 페이지로 이동');
            await _storage.write(key: 'ACCESS_TOKEN', value: data['data']['access_token']);
            
            if (data['data']['refresh_token'] != null) {
              await _storage.write(key: 'REFRESH_TOKEN', value: data['data']['refresh_token']);
            }
            
            await _storage.write(key: 'LOGIN_ID', value: email);
            await _storage.write(key: 'PASSWORD', value: 'social_login');
            
            if (onSocialLoginSuccess != null) {
              onSocialLoginSuccess!(email, displayName ?? 'Unknown');
            }
            return data;
          } else {
            log('❌ access_token이 응답에 없습니다');
          }
        
        return data;
      } else {
        log('❌ 백엔드 에러: ${response.statusCode}');
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ 백엔드 통신 에러: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
      log('✅ Google Sign-Out 완료');
    } catch (e) {
      log('❌ Google Sign-Out 에러: $e');
      rethrow;
    }
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await GoogleSignIn.instance.authenticate();
    } catch (e) {
      log('❌ 현재 사용자 정보 가져오기 에러: $e');
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    try {
      // 7.1.1 버전에서는 다른 방식으로 로그인 상태 확인
      final currentUser = await getCurrentUser();
      return currentUser != null;
    } catch (e) {
      log('❌ 로그인 상태 확인 에러: $e');
      return false;
    }
  }
}
