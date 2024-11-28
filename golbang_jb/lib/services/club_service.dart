import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/club.dart';
import '../repoisitory/secure_storage.dart';

class ClubService {
  final SecureStorage storage;

  ClubService(this.storage);

  Future<List<Club>> getClubList() async {
    // 액세스 토큰 불러오기
    final accessToken = await storage.readAccessToken();

    // API URI 설정
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/");

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
      print("jsonData: ${jsonData}");

      return (jsonData as List)
          .map((json) => Club.fromJson(json))
          .toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }
  // 모임 삭제 함수 추가
  Future<void> deleteClub(int clubId) async {
    // 액세스 토큰 불러오기
    final accessToken = await storage.readAccessToken();

    // API URI 설정
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/$clubId/");

    // 요청 헤더 설정
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    // DELETE 요청
    var response = await http.delete(uri, headers: headers);

    // 응답 확인
    if (response.statusCode == 204) {
      print("모임 삭제 성공: $clubId");
    } else {
      print("모임 삭제 실패: ${response.statusCode}");
      throw Exception('Failed to delete club');
    }
  }

  // 특정 모임 나가기
  Future<void> leaveClub(int clubId) async {
    // 액세스 토큰 불러오기
    final accessToken = await storage.readAccessToken();

    // API URI 설정
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/$clubId/leave/");

    // 요청 헤더 설정
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    // DELETE 요청
    var response = await http.delete(uri, headers: headers);

    // 응답 확인
    if (response.statusCode == 204) {
      print("모임 나가기 성공: $clubId");
    } else {
      print("모임 나가기 실패: ${response.statusCode}");
      throw Exception('Failed to leave club');
    }
  }
}