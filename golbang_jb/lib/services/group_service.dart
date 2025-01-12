import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../models/get_statistics_ranks.dart';
import '../models/profile/get_all_user_profile.dart';
import '../repoisitory/secure_storage.dart';
import 'package:golbang/models/group.dart';

class GroupService {
  //TODO: ClubService와 통합 후 삭제

  final SecureStorage storage;
  final dioClient = DioClient();

  GroupService(this.storage);

  Future<bool> saveGroup({
    required String name,
    required String description,
    required List<GetAllUserProfile> members,
    required List<GetAllUserProfile> admins,
    required File? imageFile,
  }) async {
    try {
      final url = "${dotenv.env['API_HOST']}/api/v1/clubs/";

      // 멤버와 어드민 필터링
      List<String> filteredMembers = members
          .where((e) => e.userId.toString().isNotEmpty)
          .map((e) => e.userId.toString())
          .toList();

      List<String> filteredAdmins = admins
          .where((e) => e.userId.toString().isNotEmpty)
          .map((e) => e.userId.toString())
          .toList();

      // 멀티파트 데이터 생성
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'members': filteredMembers.join(','),
        'admins': filteredAdmins.join(','),
        if (imageFile != null)
          'image': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
      });

      final response = await dioClient.dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        log('Success! Group created.');
        return true;
      } else {
        log('Failed to create group. ${response.statusCode}, ${response.data}');
        return false;
      }
    } catch (e) {
      log('Error: $e');
      return false;
    }
  }


  Future<List<Group>> getUserGroups() async {
    try {
      // API 엔드포인트 설정 (dotenv를 통해 환경 변수에서 호스트 URL을 가져옴)
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/";

      // API 요청
      var response = await dioClient.dio.get(uri);
      // 응답 상태 코드가 200인 경우, 데이터를 성공적으로 가져온 경우
      if (response.statusCode == 200) {
        // JSON 디코딩
        List<dynamic> data = response.data as List;

        // JSON 데이터를 Group 객체로 변환
        // log(data);
        List<Group> groups = data.map((groupJson) {
          try {
            return Group.fromJson(groupJson);
          } catch (e) {
            log('Error parsing group: $e');
            return null; // 파싱 오류가 발생한 경우 null 반환
          }
        }).whereType<Group>().toList(); // null이 아닌 Group 객체만 리스트에 포함

        return groups; // 그룹 리스트 반환
      } else {
        log('Failed to load groups with status code: ${response.statusCode}');
        return []; // 실패 시 빈 리스트 반환
      }
    } catch (e) {

      log('Error: $e');
      return []; // 예외 발생 시 빈 리스트 반환
    }
  }
  Future<ClubStatistics?> fetchGroupRanking(int groupId) async {
    try {
      var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/statistics/ranks/?club_id=$groupId";

      var response = await dioClient.dio.get(uri);
      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        if (jsonData != null) {
          return ClubStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      log('Failed to load club ranking: $e');
    }
    return null;
  }

  Future<List<Group>> getGroupInfo(int clubId) async {
  //TODO: 이 API가 언제 사용되는지 모르겠음. 로그에 안뜸.
    String clubidStr = clubId.toString();

    // API URI 설정
    var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/$clubidStr/";

    // API 요청
    var response = await dioClient.dio.get(uri);

    // 응답 상태 코드가 200인 경우, 데이터를 성공적으로 가져온 경우
    if (response.statusCode == 200) {
      // JSON 디코딩
      List<dynamic> groupsData = [response.data['data']];
      List<Group> groups = groupsData.map((groupJson) {
        try {
          return Group.fromJson(groupJson);
        } catch (e) {
          log('Error parsing group: $e');
          return null; // 파싱 오류가 발생한 경우 null 반환
        }
      }).whereType<Group>().toList(); // null이 아닌 Group 객체만 리스트에 포함

      return groups; // 그룹 리스트 반환
    } else {
      log('Failed to load groups with status code: ${response.statusCode}');
      return []; // 실패 시 빈 리스트 반환
    }
  }
}
