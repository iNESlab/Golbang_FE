import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
// import 'package:local_auth_ios/local_auth_ios.dart'; // iOS 생체 인증 메시지
import 'package:local_auth_android/local_auth_android.dart'; // Android 생체 인증 메시지

class BioAuth {
  static final LocalAuthentication _auth = LocalAuthentication();

  // 생체 인증이 가능한지 확인하는 함수
  static Future<bool> hasBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      print("Error checking biometrics: $e");
      return false;
    }
  }

  // 등록된 생체 인증 목록을 반환하는 함수
  static Future<List<BiometricType>> getBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print("Error getting biometrics: $e");
    }
    return <BiometricType>[];
  }

  // 생체 인증을 실행하는 함수
  static Future<bool> authenticate() async {
    final isAvailable = await hasBiometrics();
    if (!isAvailable) return false;

    try {
      return await _auth.authenticate(
          localizedReason: '생체정보를 인식해주세요.',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
            stickyAuth: true,
          ),
          authMessages: [
            // IOS 생체 인증 메세지
            // IOSAuthMessages(
            //   lockOut: '생체인식 활성화',
            //   goToSettingsButton: '설정',
            //   goToSettingsDescription: '기기 설정으로 이동하여 생체 인식을 등록하세요.',
            //   cancelButton: '취소',
            //   localizedFallbackTitle: '다른 방법으로 인증',
            // ),
            AndroidAuthMessages(
              biometricHint: '생체 정보를 스캔하세요.',
              biometricNotRecognized: '생체정보가 일치하지 않습니다.',
              biometricRequiredTitle: '생체',
              biometricSuccess: '로그인',
              cancelButton: '취소',
              deviceCredentialsRequiredTitle: '생체인식이 필요합니다.',
              deviceCredentialsSetupDescription: '기기 설정으로 이동하여 생체 인식을 등록하세요.',
              goToSettingsButton: '설정',
              goToSettingsDescription: '기기 설정으로 이동하여 생체 인식을 등록하세요.',
              signInTitle: '계속하려면 생체 인식을 스캔',
            ),
          ]
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        print("기기에서 생체 인증을 사용할 수 없음.");
      } else if (e.code == auth_error.lockedOut) {
        print("너무 많은 실패로 인해 생체 인증이 잠김.");
      } else {
        print("Authentication error: ${e.message}");
      }

      return false;
    }
  }
}