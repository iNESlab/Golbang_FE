import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golbang/global/PrivateClient.dart';
import 'package:golbang/global/PublicClient.dart';
import 'package:golbang/repoisitory/secure_storage.dart';

import '../utils/safe_dio_call.dart';

class AuthService {
  final SecureStorage storage;
  final publicClient = PublicClient();
  final privateClient = PrivateClient();
  final FlutterSecureStorage _flutterSecureStorage = const FlutterSecureStorage();

  AuthService(this.storage);

  // API 테스트 완료
  Future<Response<dynamic>?> login ({
      required String username,
      required String password,
      required String fcmToken
  }) async {
      return await safeDioCall(() async {
        var uri = "/api/v1/users/login/";
        // body
        Map data = {
          'username': username,
          'password': password,
          'fcm_token': fcmToken
        };
        var body = json.encode(data);

        var response = await publicClient.dio.post(uri, data: body);
        return response;
      }
    );
  }


  // API 테스트 완료
  Future<Response> logout() async {
    var uri = "/api/v1/users/logout/";

    try {
      // 요청 및 Authorization 헤더 추가
      var response = await privateClient.dio.post(uri);

      // 응답 상태 확인
      if (response.statusCode == 202) {
        // 로그아웃 성공 시 스토리지에 있는 액세스 토큰 삭제
        await _flutterSecureStorage.delete(key: "ACCESS_TOKEN");
        log('로그아웃 성공: 토큰 삭제 완료');

      }

      return response;
    } catch (e) {
      log("로그아웃 실패: $e");
      rethrow; // 에러를 호출한 곳으로 전달
    }
  }

}

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage);
});