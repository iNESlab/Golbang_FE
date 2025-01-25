import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:http/http.dart' as http;

import '../global/LoginInterceptor.dart';

class AuthService {
  final SecureStorage storage;
  final dioClient = DioClient();
  final FlutterSecureStorage _flutterSecureStorage = const FlutterSecureStorage();

  AuthService(this.storage);

  static Future<http.Response> login ({
      required String username,
      required String password,
      required String fcm_token
  }) async {
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/login/");
    Map<String, String> headers = {"Content-type": "application/json"};
    // body
    Map data = {
      'username': username,
      'password': password,
      'fcm_token': fcm_token
    };
    var body = json.encode(data);
    try {
      // 요청 시작 로그
      log("Sending POST request to $uri with body: $data");

      var response = await http.post(uri, headers: headers, body: body);

      // 응답 상태 로그
      log("Response received: Status code ${response.statusCode}");

      // 응답 바디 로그
      log("Response body: ${json.decode(utf8.decode(response.bodyBytes))}");

      return response;
    } catch (e, stackTrace) {
      // 오류 로그
      log("Error occurred during POST request: $e", error: e, stackTrace: stackTrace);

      // 재던지기 (오류를 호출자에게 전달)
      rethrow;
    }
  }

  Future<Response> logout() async {
    var uri = "${dotenv.env['API_HOST']}/api/v1/users/logout/";

    try {
      // 요청 및 Authorization 헤더 추가
      var response = await dioClient.dio.post(uri);

      // 응답 상태 확인
      if (response.statusCode == 202) {
        // 로그아웃 성공 시 스토리지에 있는 액세스 토큰 삭제
        await _flutterSecureStorage.deleteAll();
        log('로그아웃 성공: 토큰 삭제 완료');

      }

      return response;
    } catch (e) {
      log("로그아웃 실패: $e");
      rethrow; // 에러를 호출한 곳으로 전달
    }
  }
  //TODO: 유효성 검사하는데 왜 로그 아웃 API를 사용하는지 확인
  Future<Response> validateToken() async {
    var uri = "${dotenv.env['API_HOST']}/api/v1/users/logout/"; // TODO 삭제
    var response =  await dioClient.dio.post(uri);
    return response;
  }
}
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage);
});