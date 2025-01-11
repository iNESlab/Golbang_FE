import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../global/LoginInterceptor.dart';

class AuthService {
  final SecureStorage storage;
  final dioClient = DioClient();

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
      'username': '$username',
      'password': '$password',
      'fcm_token': '$fcm_token'
    };
    var body = json.encode(data);
    // login은 액세스 토큰을 안쓰므로 dio를 안거치도록 함
    var response = await http.post(uri, headers: headers, body: body);
    log("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }

  Future<Response> logout() async {
    var uri = "${dotenv.env['API_HOST']}/api/v1/users/logout/";

    try {
      // 요청 및 Authorization 헤더 추가
      var response = await dioClient.dio.post(uri);

      // 응답 상태 확인
      if (response.statusCode == 202) {
        // 로그아웃 성공 시 자동 로그인 비활성화
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAutoLoginEnabled', false);
      }

      return response;
    } catch (e) {
      log("로그아웃 실패: $e");
      rethrow; // 에러를 호출한 곳으로 전달
    }
  }
  //TODO: 유효성 검사하는데 왜 로그 아웃 API를 사용하는지 확인
  Future<Response> validateToken() async {
    var uri = "${dotenv.env['API_HOST']}/api/v1/users/logout/";
    var response =  await dioClient.dio.post(uri);
    return response;
  }
}
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage);
});