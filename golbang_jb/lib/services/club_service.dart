import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../models/club.dart';
import '../models/profile/get_all_user_profile.dart';
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

  Future<void> inviteMembers(int clubId, List<GetAllUserProfile> userProfileList) async {
    try {
      for (var user in userProfileList) {
        log('username: ${user.name}'); // ✅ user_id 출력
      }
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/$clubId/invite/";

      // 1️⃣ userProfileList에서 user_id만 추출하여 리스트로 변환
      List<String> userIds = userProfileList.map((userProfile) => userProfile.userId).toList();

      // 2️⃣ 서버로 리스트를 한 번에 전송
      await dioClient.dio.post(
        uri,
        data: {
          "user_ids": userIds, // ✅ 리스트로 변환된 user_ids 전송
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

    } catch (e) {
      log('Error inviting members: $e');
    }
  }
  Future<void> removeMember(int clubId, int memberId) async {
    try {
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/$clubId/members/$memberId/";

      await dioClient.dio.delete(
        uri,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      log('Successfully removed member: $memberId from club: $clubId');
    } catch (e) {
      log('Error removing member: $e');
    }
  }
}