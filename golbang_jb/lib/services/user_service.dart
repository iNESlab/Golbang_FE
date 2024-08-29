import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_profile.dart';
import '../repoisitory/secure_storage.dart';

class UserService {
  final SecureStorage storage;

  UserService(this.storage);

  Future<List<UserProfile>> getUserProfileList() async {
    // 액세스 토큰 불러오기
    final accessToken = await storage.readAccessToken();

    // API URI 설정
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/info/");

    // 요청 헤더 설정
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": "Bearer $accessToken"
    };

    // API 요청
    var response = await http.get(uri, headers: headers);
    print("${json.decode(utf8.decode(response.bodyBytes))}");

    // 응답 코드가 200(성공)인지 확인
    if (response.statusCode == 200) {
      // JSON 데이터 파싱
      var jsonData = json.decode(utf8.decode(response.bodyBytes));
      print("json: ${jsonData['data']}");

      return (jsonData['data'] as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }

  Future<UserProfile> getUserProfile() async {
    try {
      // 액세스 토큰 불러오기
      final accessToken = await storage.readAccessToken();
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      print('decodedToken: $decodedToken');
      String userId = decodedToken['user_id'].toString(); // payload에서 user_id 추출
      print('userId from token $userId');
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/info/$userId/");

      // 요청 헤더 설정
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };
      // API 요청
      var response = await http.get(uri, headers: headers);
      //print(response.statusCode);
      // 응답 코드가 200(성공)인지 확인
      if (response.statusCode == 200) {
        // JSON 데이터 파싱
        var jsonData = json.decode(utf8.decode(response.bodyBytes));
        print("json: ${jsonData}");
        // 이유는 모르나 code / message /data 형태로 반환이 안됨. data만 반환됨
        return UserProfile.fromJson(jsonData);
      } else {
        throw Exception('Failed to load user profiles');
      }
    } catch (e) {
      print('Error decoding token: $e');
      // 예외를 다시 던져서 함수가 항상 반환값을 가지도록 함
      throw Exception('Error decoding token: $e');
    }
  }


  static Future<http.Response> saveUser({
    required String userId,
    required String email,
    required String password1,
    required String password2
  }) async {

    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/signup/step-1/");
    Map<String, String> headers = {"Content-type": "application/json"};
    // body
    Map data = {
      'user_id': '$userId',
      'email': '$email',
      'password1': '$password1',
      'password2': '$password2',
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }

  static Future<http.Response> saveAdditionalInfo({
    required int userId,
    required String name,
    String? phoneNumber,
    int? handicap,
    String? dateOfBirth,
    String? address,
    String? studentId
  })async{

    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/signup/step-2/");
    Map<String, String> headers = {"Content-type": "application/json"};
    // body
    Map data = {
      'user_id': '$userId',
      'name': '$name',
      'phone_number': '$phoneNumber',
      'handicap': '$handicap',
      'date_of_birth': '$dateOfBirth',
      'address': '$address',
      'student_id': '$studentId',
    };

    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${json.decode(utf8.decode(response.bodyBytes))}");

    return response;
  }
}