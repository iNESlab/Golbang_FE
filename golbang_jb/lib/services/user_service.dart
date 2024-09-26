import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/profile/get_all_user_profile.dart';
import '../models/profile/get_event_result_participants_ranks.dart';
import '../models/user_account.dart';
import '../repoisitory/secure_storage.dart';

class UserService {
  final SecureStorage storage;

  UserService(this.storage);

  Future<List<GetAllUserProfile>> getUserProfileList() async {
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
          .map((json) => GetAllUserProfile.fromJson(json))
          .toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }

  Future<GetAllUserProfile> getUserProfile() async {
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
      // 응답 코드가 200(성공)인지 확인
      if (response.statusCode == 200) {
        // JSON 데이터 파싱
        var jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        print("==============================json: ${jsonData}");
        // 이유는 모르나 code / message /data 형태로 반환이 안됨. data만 반환됨 => 해결완료
        return GetAllUserProfile.fromJson(jsonData);
      } else {
        throw Exception('Failed to load user profiles');
      }
    } catch (e) {
      print('Error decoding token: $e');
      // 예외를 다시 던져서 함수가 항상 반환값을 가지도록 함
      throw Exception('Error decoding token: $e');
    }
  }

  Future<UserAccount> getUserInfo() async {
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
      // 응답 코드가 200(성공)인지 확인
      if (response.statusCode == 200) {
        // JSON 데이터 파싱
        var jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        print("=================user정보조회=============json: ${jsonData}");
        // 이유는 모르나 code / message /data 형태로 반환이 안됨. data만 반환됨 => 해결완료
        return UserAccount.fromJson(jsonData);
      } else {
        throw Exception('Failed to load user profiles');
      }
    } catch (e) {
      print('Error decoding token: $e');
      // 예외를 다시 던져서 함수가 항상 반환값을 가지도록 함
      throw Exception('Error decoding token: $e');
    }
  }

  Future<UserAccount> updateUserInfo({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
    int? handicap,
    DateTime? dateOfBirth, // DateTime 형식
    String? address,
    String? studentId,
    //File? profileImage, // 이미지 파일
  }) async {
    try {
      // 액세스 토큰 불러오기
      final accessToken = await storage.readAccessToken();
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      String userId = decodedToken['user_id'].toString();

      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/info/$userId/");

      // 요청 헤더 설정
      Map<String, String> headers = {
        "Authorization": "Bearer $accessToken",
      };

      // Multipart 요청을 위한 객체 생성
      var request = http.MultipartRequest('PATCH', uri);
      request.headers.addAll(headers);

      // JSON 필드 추가 (변경된 값만 추가)
      Map<String, String> fields = {};
      if (name != null && name.isNotEmpty) fields['name'] = name;
      if (email != null && email.isNotEmpty) fields['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) fields['phone_number'] = phoneNumber;
      if (handicap != null) fields['handicap'] = handicap.toString();

      // 날짜 포맷팅 추가
      if (dateOfBirth != null) {
        String formattedDate = "${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";
        fields['date_of_birth'] = formattedDate;
      }

      if (address != null && address.isNotEmpty) fields['address'] = address;
      if (studentId != null && studentId.isNotEmpty) fields['student_id'] = studentId;

      request.fields.addAll(fields);

      // // 프로필 이미지 처리: 이미지가 있으면 파일 전송, 없으면 빈 문자열 전송
      // if (profileImage != null) {
      //   request.files.add(
      //     await http.MultipartFile.fromPath('profile_image', profileImage.path),
      //   );
      // } else {
      //   // 이미지가 없는 경우, 빈 문자열을 서버에 전송
      //   fields['profile_image'] = '';  // 서버가 이 값을 보고 이미지 삭제 처리
      // }

      // 요청 전송
      var response = await request.send();

      // 응답 처리
      if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonData = json.decode(responseData)['data'];
          print("===============내정보 수정 성공===============json: ${jsonData}");
          print("request $fields");

        return UserAccount.fromJson(jsonData);
      } else {
        var responseData = await response.stream.bytesToString();
        print('Failed to update user info: ${response.statusCode}, ${responseData}');
        throw Exception('Failed to update user info');
      }
    } catch (e) {
      print('Error updating user info: $e');
      throw Exception('Error updating user info: $e');
    }
  }

  Future<void> deleteProfileImage({required String userId}) async {
    final accessToken = await storage.readAccessToken();
    Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
    String userId = decodedToken['user_id'].toString();

    final uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/info/$userId/delete-profile-image/");

    final response = await http.delete(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );
    if (response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        print("Response body: ${response.body}");
        print("===============프로필 사진 제거 성공==============");

      } else {
        print("No content in response");
      }

    }
    else {
      throw Exception('Failed to delete profile image');
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