import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import '../global/PrivateClient.dart';
import '../models/club.dart';
import '../models/member.dart';
import '../models/profile/get_all_user_profile.dart';
import '../models/responseDTO/GolfClubResponseDTO.dart';
import '../models/responseDTO/CourseResopnseDTO.dart';
import '../repoisitory/secure_storage.dart';
import '../utils/safe_dio_call.dart';

class ClubService {
  final SecureStorage storage;
  final privateClient = PrivateClient();

  ClubService(this.storage);

  // API 테스트 완료
  Future<Club?> getClub({required int clubId}) async {
    return await safeDioCall(() async {
      // API URI 설정
      var uri = "/api/v1/clubs/$clubId/";
      // API 요청
      var response = await privateClient.dio.get(uri);

      // 응답 코드가 200(성공)인지 확인
      if (response.statusCode == 200) {
        var data = response.data['data'];
        return Club.fromJson(data);
      } else {
        // 오류 발생 시 예외를 던짐
        throw Exception('Failed to load user profiles');
      }
    });
  }

  // API 테스트 완료
  Future<List<Club>> getMyClubList({bool isAdmin=false}) async {

    // API URI 설정
    var uri = "/api/v1/clubs/";
    // API 요청
    var response = await privateClient.dio.get(uri);

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

  // API 테스트 완료
  Future<List<Club>?> searchClubList(String query) async {
    return await safeDioCall<List<Club>>(() async {
      // API URI 설정
      var uri = "/api/v1/clubs/search/?club_name=$query";
      // API 요청
      var response = await privateClient.dio.get(uri);

      var data = response.data['data'];
      return (data as List).map((json) => Club.fromJson(json)).toList();
      });
    }

  Future<void> applyClub(int clubId) async {
    return await safeDioCall<void>(() async {
      // API URI 설정
      var uri = "/api/v1/clubs/$clubId/apply/";
      // API 요청
      await privateClient.dio.post(uri);
    });
  }

  // API 테스트 완료
  // 모임 삭제 함수 추가
  Future<void> deleteClub(int clubId) async {

    // API URI 설정
    var uri = "/api/v1/clubs/admin/$clubId/";
    // DELETE 요청
    var response = await privateClient.dio.delete(uri);

    // 응답 확인
    if (response.statusCode != 204) {
      throw Exception('Failed to delete club');
    }
  }

  // API 테스트 완료
  // 특정 모임 나가기
  Future<void> leaveClub(int clubId) async {
    // API URI 설정
    var uri = "/api/v1/clubs/$clubId/leave/";
    // DELETE 요청
    var response = await privateClient.dio.delete(uri);
    // 응답 확인
    if (response.statusCode != 204) {
      throw Exception('Failed to leave club');
    }
  }

  // API 테스트 완료
  Future<List<Member>> inviteMembers(int clubId, List<GetAllUserProfile> userProfileList) async {
    try {
      for (var user in userProfileList) {
        log('username: ${user.name}'); // ✅ user_id 출력
      }
      // TODO: 다른 api와는 다르게 모임 초대할 때에는 PK가 아니라 유저 아이디로 초대하고 있음. 통일이 필요
      var uri = "/api/v1/clubs/admin/$clubId/invite/";

      // 1️⃣ userProfileList에서 user_id만 추출하여 리스트로 변환
      List<String> userIds = userProfileList.map((userProfile) => userProfile.userId!).toList();

      // 2️⃣ 서버로 리스트를 한 번에 전송
      final response = await privateClient.dio.post(
        uri,
        data: {
          "user_ids": userIds, // ✅ 리스트로 변환된 user_ids 전송
        },
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

  // API 테스트 완료
  Future<void> removeMember(int clubId, int memberId) async {
    return await safeDioCall(() async {
      var uri = "/api/v1/clubs/admin/$clubId/members/$memberId/";

      await privateClient.dio.delete(uri);
    });
  }

  Future<void> acceptMember(int clubId, int memberId) async {
    return await safeDioCall(() async {
        var uri = "/api/v1/clubs/admin/$clubId/members/$memberId/status/";
        await privateClient.dio.patch(uri);
    });
  }

  // API 테스트 완료
  Future<bool> updateClubWithAdmins({
    required int clubId,
    required String name,
    required String description,
    required List<int> adminIds,
    File? imageFile}) async {
    try {
      var uri = "/api/v1/clubs/admin/$clubId/";
      late FormData formData;
      List<String> filteredAdmins = adminIds
          .map((e) => e.toString())
          .toList();
      late Response<dynamic> response;

      if (imageFile == null){
        response = await privateClient.dio.patch(
          uri,
          data: {
            "name": name,
            "description": description,
            "admins": adminIds, // ✅ 리스트로 변환된 user_ids 전송
          },
        );
      } else{
        // 멀티파트 데이터 생성
        formData = FormData.fromMap({
          'name': name,
          'description': description,
          'admins': filteredAdmins.join(','),
          'image': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        });

        response = await privateClient.dio.patch(
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

  // 골프장 목록 조회
  Future<List<GolfClubResponseDTO>> getGolfClubs() async {
    try {
      final response = await privateClient.dio.get('/api/v1/golfcourses/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => GolfClubResponseDTO.fromJson(json)).toList();
      } else {
        log('골프장 목록 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error occurred while fetching golf clubs: $e');
      return [];
    }
  }

  // 특정 골프장의 코스 목록 조회
  Future<List<CourseResponseDTO>> getGolfCourses(int golfClubId) async {
    try {
      log('골프장 코스 조회 시작 - golfClubId: $golfClubId');
      final response = await privateClient.dio.get('/api/v1/golfcourses/?golfclub_id=$golfClubId');
      
      log('API 응답 상태: ${response.statusCode}');
      log('API 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> clubData = response.data['data'];
        final List<dynamic> coursesData = clubData['courses'];
        log('파싱할 코스 데이터: $coursesData');
        
        final courses = coursesData.map((json) => CourseResponseDTO.fromJson(json)).toList();
        log('파싱된 코스 개수: ${courses.length}');
        
        return courses;
      } else {
        log('골프장 코스 목록 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error occurred while fetching golf courses: $e');
      return [];
    }
  }

}