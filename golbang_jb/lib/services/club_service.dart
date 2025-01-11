import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../models/club.dart';
import '../repoisitory/secure_storage.dart';

class ClubService {
  final SecureStorage storage;
  final dioClient = DioClient();

  ClubService(this.storage);

  Future<List<Club>> getClubList({bool isAdmin=false}) async {

    // API URI 설정
    var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/";
    // API 요청
    var response = await dioClient.dio.get(uri);

    // 응답 코드가 200(성공)인지 확인
    if (response.statusCode == 200) {
      var data = response.data;
      if(isAdmin) {
        data = data.where((item) => item['is_admin'] == true).toList();
      }

      return (data as List).map((json) => Club.fromJson(json)).toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }
  // 모임 삭제 함수 추가
  Future<void> deleteClub(int clubId) async {

    // API URI 설정
    var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/$clubId/";
    // DELETE 요청
    var response = await dioClient.dio.delete(uri);

    // 응답 확인
    if (response.statusCode != 204) {
      throw Exception('Failed to delete club');
    }
  }

  // 특정 모임 나가기
  Future<void> leaveClub(int clubId) async {
    // API URI 설정
    var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/$clubId/leave/";
    // DELETE 요청
    var response = await dioClient.dio.delete(uri);
    // 응답 확인
    if (response.statusCode != 204) {
      throw Exception('Failed to leave club');
    }
  }
}