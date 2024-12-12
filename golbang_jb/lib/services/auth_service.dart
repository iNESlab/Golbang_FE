import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final SecureStorage storage;

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
    var response = await http.post(uri, headers: headers, body: body);
    print("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }

  Future<http.Response> logout() async {
    // API 엔드포인트 설정 (dotenv를 통해 환경 변수에서 호스트 URL을 가져옴)
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/logout/");
    final accessToken = await storage.readAccessToken();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": "Bearer $accessToken"
    };

    // API 요청
    var response = await http.post(uri, headers: headers);
    print("${json.decode(utf8.decode(response.bodyBytes))}");
    // 응답 상태 코드가 202인 경우, 데이터를 성공적으로 가져온 경우
    return response;
  }
}