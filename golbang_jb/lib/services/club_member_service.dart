import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/profile/member_profile.dart';
import '../repoisitory/secure_storage.dart';

class ClubMemberService {
  final SecureStorage storage;

  ClubMemberService(this.storage);

  Future<List<ClubMemberProfile>> getClubMemberProfileList({
    required int club_id,
  }) async {
    // 액세스 토큰 불러오기
    final accessToken = await storage.readAccessToken();

    // API URI 설정
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/$club_id/members/");

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
          .map((json) => ClubMemberProfile.fromJson(json))
          .toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }
}