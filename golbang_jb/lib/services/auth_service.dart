import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golbang/global/PrivateClient.dart';
import 'package:golbang/global/PublicClient.dart';
import 'package:golbang/repoisitory/secure_storage.dart';

class AuthService {
  final SecureStorage storage;
  final publicClient = PublicClient();
  final privateClient = PrivateClient();
  final FlutterSecureStorage _flutterSecureStorage = const FlutterSecureStorage();

  AuthService(this.storage);

  // API 테스트 완료
  Future<Response<dynamic>> login ({
      required String username,
      required String password,
      required String fcmToken
  }) async {
    var uri = "/api/v1/users/login/";
    // body
    Map data = {
      'username': username,
      'password': password,
      'fcm_token': fcmToken
    };
    var body = json.encode(data);
    try {
      // 요청 시작 로그
      log("Sending POST request to $uri with body: $data");

      var response = await publicClient.dio.post(uri, data: body);

      // 응답 상태 로그
      log("Response received: Status code ${response.statusCode}");

      // 응답 바디 로그
      log("Response body: ${response.data['data']}");

      return response;
    } catch (e, stackTrace) {
      // 오류 로그
      log("Error occurred during POST request: $e", error: e, stackTrace: stackTrace);

      // 재던지기 (오류를 호출자에게 전달)
      rethrow;
    }
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