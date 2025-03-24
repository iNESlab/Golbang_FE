import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../models/club.dart';
import '../models/member.dart';
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
    var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/admin/$clubId/";
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

  Future<List<Member>> inviteMembers(int clubId, List<GetAllUserProfile> userProfileList) async {
    try {
      for (var user in userProfileList) {
        log('username: ${user.name}'); // ✅ user_id 출력
      }
      // TODO: 다른 api와는 다르게 모임 초대할 때에는 PK가 아니라 유저 아이디로 초대하고 있음. 통일이 필요
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/admin/$clubId/invite/";

      // 1️⃣ userProfileList에서 user_id만 추출하여 리스트로 변환
      List<String> userIds = userProfileList.map((userProfile) => userProfile.userId!).toList();

      // 2️⃣ 서버로 리스트를 한 번에 전송
      final response = await dioClient.dio.post(
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

      if (response.statusCode != 204) {
        return (response.data['data'] as List).map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception('Failed to leave club');
      }

    } catch (e) {
      log('Error inviting members: $e');
      throw Exception('Failed to invite member');
    }
  }
  Future<void> removeMember(int clubId, int memberId) async {
    try {
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/admin/$clubId/members/$memberId/";

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

  Future<bool> updateClubWithAdmins({
    required int clubId,
    required String name,
    required String description,
    required List<int> adminIds,
    File? imageFile}) async {
    try {
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/admin/$clubId/";
      late FormData formData;
      List<String> filteredAdmins = adminIds
          .map((e) => e.toString())
          .toList();
      late Response<dynamic> response;

      if (imageFile == null){
        response = await dioClient.dio.patch(
          uri,
          data: {
            "name": name,
            "description": description,
            "admins": adminIds, // ✅ 리스트로 변환된 user_ids 전송
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );
      } else{
        // 멀티파트 데이터 생성
        formData = FormData.fromMap({
          'name': name,
          'description': description,
          'admins': filteredAdmins.join(','),
          'image': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        });

        response = await dioClient.dio.patch(
          uri,
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );
      }

      if (response.statusCode == 200) {
        log('Success! Club updated.');
        return true;
      } else {
        log('Failed to update club. ${response.statusCode}, ${response.data}');
        return false;
      }

    } catch (e) {
      log('Error removing member: $e');
      return false;
    }
  }

}