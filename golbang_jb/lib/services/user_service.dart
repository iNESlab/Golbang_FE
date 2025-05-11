import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../global/PrivateClient.dart';
import '../global/PublicClient.dart';
import '../models/profile/get_all_user_profile.dart';
import '../models/user_account.dart';
import '../repoisitory/secure_storage.dart';

class UserService {
  final SecureStorage storage;
  final privateClient = PrivateClient();
  final publicClient = PublicClient();
  final FlutterSecureStorage _flutterSecureStorage = const FlutterSecureStorage();

  UserService(this.storage);

  // 로그인 여부 확인하는 임시 코드
  Future<bool> isLoggedIn() async {
    final String accessToken = await storage.readAccessToken();
    return accessToken.isNotEmpty;
  }

  // API 테스트 완료
  Future<List<GetAllUserProfile>> getUserProfileList() async {
    // API URI 설정
    var uri = "/api/v1/users/info/";

    // API 요청
    var response = await privateClient.dio.get(uri);

    // 응답 코드가 200(성공)인지 확인
    if (response.statusCode == 200) {
      var jsonData = response.data;

      return (jsonData['data'] as List)
          .map((json) => GetAllUserProfile.fromJson(json))
          .toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }

  // API 테스트 완료
  Future<GetAllUserProfile> getUserProfile() async {
    try {
      // 액세스 토큰 불러오기
      //TODO: 토큰 파싱해서 id로 직접 조회는 안하기로 한걸로 아는데 일단 메모.
      final accessToken = await storage.readAccessToken();
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      String userId = decodedToken['user_id'].toString(); // payload에서 user_id 추출
      var uri = "/api/v1/users/info/$userId/";

      var response = await privateClient.dio.get(uri);
      // 응답 코드가 200(성공)인지 확인
      if (response.statusCode == 200) {
        // JSON 데이터 파싱
        var jsonData = response.data['data'];
        return GetAllUserProfile.fromJson(jsonData);
      } else {
        throw Exception('Failed to load user profiles');
      }
    } catch (e) {
      log('Error decoding token: $e');
      // 예외를 다시 던져서 함수가 항상 반환값을 가지도록 함
      throw Exception('Error decoding token: $e');
    }
  }

  // API 테스트 완료
  Future<UserAccount> getUserInfo() async {
    // TODO: 위와 같은 API를 사용하므로 하나로 합칠 수 있는지 검토
    try {
      // 액세스 토큰 불러오기
      final accessToken = await storage.readAccessToken();
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      String userId = decodedToken['user_id'].toString(); // payload에서 user_id 추출
      var uri = "/api/v1/users/info/$userId/";

      // API 요청
      var response = await privateClient.dio.get(uri);
      // 응답 코드가 200(성공)인지 확인
      if (response.statusCode == 200) {
        // JSON 데이터 파싱
        var jsonData = response.data['data'];
        // 이유는 모르나 code / message /data 형태로 반환이 안됨. data만 반환됨 => 해결완료
        return UserAccount.fromJson(jsonData);
      } else {
        throw Exception('Failed to load user profiles');
      }
    } catch (e) {
      log('Error decoding token: $e');
      // 예외를 다시 던져서 함수가 항상 반환값을 가지도록 함
      throw Exception('Error decoding token: $e');
    }
  }

  // API 테스트 완료
  Future<UserAccount> updateUserInfo({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
    int? handicap,
    DateTime? dateOfBirth,
    String? address,
    String? studentId,
    File? profileImage,
  }) async {
    try {
      // 액세스 토큰 불러오기
      final accessToken = await storage.readAccessToken();
      final decodedToken = JwtDecoder.decode(accessToken);
      userId = decodedToken['user_id'].toString();

      final url = "/api/v1/users/info/$userId/";

      // JSON 필드 추가 (변경된 값만 추가)
      Map<String, dynamic> fields = {};
      if (name != null && name.isNotEmpty) fields['name'] = name;
      if (email != null && email.isNotEmpty) fields['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) fields['phone_number'] = phoneNumber;
      if (handicap != null) fields['handicap'] = handicap;
      if (dateOfBirth != null) {
        fields['date_of_birth'] =
        "${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";
      }
      if (address != null && address.isNotEmpty) fields['address'] = address;
      if (studentId != null && studentId.isNotEmpty) fields['student_id'] = studentId;

      // FormData 생성 (멀티파트 데이터 지원)
      final formData = FormData.fromMap({
        ...fields, // JSON 필드 추가
        if (profileImage != null)
          'profile_image': await MultipartFile.fromFile(profileImage.path),
        if (profileImage == null) 'profile_image': '', // 이미지 삭제 처리
      });

      // Dio 요청 보내기
      final response = await privateClient.dio.patch(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data', // 멀티파트 요청을 위한 헤더
          },
        ),
      );

      // 응답 처리
      if (response.statusCode == 200) {
        return UserAccount.fromJson(response.data['data']);
      } else {
        log('Failed to update user info: ${response.statusCode}, ${response.data}');
        throw Exception('Failed to update user info');
      }
    } catch (e) {
      log('Error updating user info: $e');
      throw Exception('Error updating user info: $e');
    }
  }


  // TODO: 추후 S3 삭제가 정상적으로 될 경우 아래 로직을 이용할 예정
  // Future<void> deleteProfileImage({required String userId}) async {
  //   final accessToken = await storage.readAccessToken();
  //   Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
  //   String userId = decodedToken['user_id'].toString();
  //
  //   final uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/users/info/$userId/delete-profile-image/");
  //
  //   final response = await http.delete(
  //     uri,
  //     headers: {
  //       "Authorization": "Bearer $accessToken",
  //     },
  //   );
  //   if (response.statusCode == 204) {
  //     if (response.body.isNotEmpty) {
  //       log("Response body: ${response.body}");
  //       log("===============프로필 사진 제거 성공==============");
  //
  //     } else {
  //       log("No content in response");
  //     }
  //
  //   }
  //   else {
  //     throw Exception('Failed to delete profile image');
  //   }
  // }

  // API 테스트 완료
  Future<Response<dynamic>> saveUser({
    required String userId,
    required String email,
    required String password1,
    required String password2
  }) async {

    var uri = Uri.parse("/api/v1/users/signup/step-1/");
    // body
    Map data = {
      'user_id': userId,
      'email': email,
      'password1': password1,
      'password2': password2,
    };
    var body = json.encode(data);
    var response = await publicClient.dio.postUri(uri, data: body);

    log("${response.data['data']}");

    return response;
  }

  // API 테스트 완료
  Future<Response<dynamic>> saveAdditionalInfo({
    required int userId,
    required String name,
    String? phoneNumber,
    int? handicap,
    String? dateOfBirth,
    String? address,
    String? studentId
  })async{

    var uri = Uri.parse("/api/v1/users/signup/step-2/");
    // body
    Map data = {
      'user_id': '$userId',
      'name': name,
      'phone_number': '$phoneNumber',
      'handicap': '$handicap',
      'date_of_birth': '$dateOfBirth',
      'address': '$address',
      'student_id': '$studentId',
    };
    var body = json.encode(data);
    var response = await publicClient.dio.postUri(uri, data: body);

    return response;
  }

  // API 테스트 완료
  Future<Response<dynamic>> resetPassword({required String email})async{
    var uri = Uri.parse("/api/v1/users/info/password/forget/");
    // body
    Map data = {
      'email': email,
    };

    var body = json.encode(data);
    var response = await publicClient.dio.postUri(uri, data: body);

    log("${response.data['data']}");

    return response;
  }

  // API 테스트 완료
  Future<Response> deleteAccount() async {

    var uri = "/api/v1/users/info/delete/";

    var response = await privateClient.dio.delete(uri);
    // 에러처리는 scafford에서 진행되므로 페이지에서 진행
    await _flutterSecureStorage.delete(key: "ACCESS_TOKEN");

    return response;
  }

  // Future<bool> updatePassword(string newPassword) async {
  //   var uri = "${dotenv.env['API_HOST']}/api/v1/users/info/delete/";
  //
  //   var response = await dioClient.dio.patch(uri, data: {'password': newPassword});
  // }
}