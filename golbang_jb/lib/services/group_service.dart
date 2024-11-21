import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/models/profile/get_event_result_participants_ranks.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart'; // basename을 사용하기 위해 필요
import '../models/get_statistics_ranks.dart';
import '../models/profile/get_all_user_profile.dart';
import '../repoisitory/secure_storage.dart';
import 'package:golbang/models/group.dart';

class GroupService {
  final SecureStorage storage;

  GroupService(this.storage);

  Future<bool> saveGroup({
    required String name,
    required String description,
    required List<GetAllUserProfile> members,
    required List<GetAllUserProfile> admins,
    required File? imageFile, // 이미지 파일 추가
  }) async {
    try {
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/"); // 서버의 API 엔드포인트

      var request = http.MultipartRequest('POST', uri);

      // 이미지 파일이 있는 경우 추가
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // 서버에서 기대하는 필드 이름
            imageFile.path,
            filename: basename(imageFile.path),
          ),
        );
      }

      // 로그 찍기 - 원래의 members와 admins 리스트 출력
      print('Original members: ${members.map((e) => e.userId.toString()).toList()}');
      print('Original admins: ${admins.map((e) => e.userId.toString()).toList()}');

// 필터링된 members와 admins 리스트를 생성하며, 로그 출력
      List<String> filteredMembers = members
          .where((e) => e.userId != null && e.userId.toString().isNotEmpty)
          .map((e) => e.userId.toString())
          .toList();
      print('Filtered members: $filteredMembers');

      List<String> filteredAdmins = admins
          .where((e) => e.userId != null && e.userId.toString().isNotEmpty)
          .map((e) => e.userId.toString())
          .toList();
      print('Filtered admins: $filteredAdmins');


// 로그 찍기 - members와 admins 리스트를 콤마로 조합한 후 출력
      String membersString = filteredMembers.join(',');
      String adminsString = filteredAdmins.join(',');

      print('Members string: $membersString');
      print('Admins string: $adminsString');

      // 데이터 추가

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['members'] = membersString;
      request.fields['admins'] = adminsString;


      // 헤더에 인증 토큰 추가 (필요한 경우)
      final accessToken = await storage.readAccessToken();
      request.headers['Authorization'] = 'Bearer $accessToken';

      // 서버에 요청 보내기
      final response = await request.send();

      if (response.statusCode == 201) {

        print('Success! Group created.');
        return true;
      } else {
        var responseData = await response.stream.bytesToString();
        print('Failed to create group. ${response.statusCode}, ${responseData}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }


  Future<List<Group>> getUserGroups() async {
    try {
      // API 엔드포인트 설정 (dotenv를 통해 환경 변수에서 호스트 URL을 가져옴)
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/");

      // 토큰을 읽어와서 인증 헤더 설정
      final accessToken = await storage.readAccessToken(); // storage는 로컬 저장소에 접근하는 클래스의 인스턴스입니다.
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };

      // API 요청
      var response = await http.get(uri, headers: headers);
      // 응답 상태 코드가 200인 경우, 데이터를 성공적으로 가져온 경우
      if (response.statusCode == 200) {
        // JSON 디코딩
        List<dynamic> data = jsonDecode(response.body);

        // JSON 데이터를 Group 객체로 변환
        print(data);
        List<Group> groups = data.map((groupJson) {
          try {
            return Group.fromJson(groupJson);
          } catch (e) {
            print('Error parsing group: $e');
            return null; // 파싱 오류가 발생한 경우 null 반환
          }
        }).whereType<Group>().toList(); // null이 아닌 Group 객체만 리스트에 포함

        return groups; // 그룹 리스트 반환
      } else {
        print('Failed to load groups with status code: ${response.statusCode}');
        return []; // 실패 시 빈 리스트 반환
      }
    } catch (e) {

      print('Error: $e');
      return []; // 예외 발생 시 빈 리스트 반환
    }
  }
  Future<ClubStatistics?> fetchGroupRanking(int groupId) async {
    try {
      final accessToken = await storage.readAccessToken();
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/statistics/ranks/?club_id=$groupId");

      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };

      var response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        print("=========In fetchGroupRanking");
        print(groupId);
        print(jsonData);
        if (jsonData != null) {
          return ClubStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      print('Failed to load club ranking: $e');
    }
    return null;
  }
  // Future<List<Group>> getGroupInfo(int clubId) async {
  //   // 액세스 토큰 불러오기
  //   final accessToken = await storage.readAccessToken();
  //   String clubId_str = clubId.toString();
  //   // API URI 설정
  //   var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/$clubId_str/");
  //   print(uri);
  //   // 요청 헤더 설정
  //   Map<String, String> headers = {
  //     "Content-type": "application/json",
  //     "Authorization": "Bearer $accessToken"
  //   };
  //
  //   // API 요청
  //   var response = await http.get(uri, headers: headers);
  //
  //   // 응답 상태 코드가 200인 경우, 데이터를 성공적으로 가져온 경우
  //   if (response.statusCode == 200) {
  //     // JSON 디코딩
  //     final Map<String, dynamic> data = jsonDecode(response.body);
  //     List<dynamic> groupsData = [data['data']];
  //     List<Group> groups = groupsData.map((groupJson) {
  //       try {
  //         return Group.fromJson(groupJson);
  //       } catch (e) {
  //         print('Error parsing group: $e');
  //         return null; // 파싱 오류가 발생한 경우 null 반환
  //       }
  //     }).whereType<Group>().toList(); // null이 아닌 Group 객체만 리스트에 포함
  //
  //     return groups; // 그룹 리스트 반환
  //   } else {
  //     print('Failed to load groups with status code: ${response.statusCode}');
  //     return []; // 실패 시 빈 리스트 반환
  //   }
  // }
  Future<List<Group>> getGroupInfo(int clubId) async {
    final accessToken = await storage.readAccessToken();
    String clubId_str = clubId.toString();
    var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/$clubId_str/");
    print(uri);

    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": "Bearer $accessToken"
    };

    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      List<dynamic> groupsData = [data['data']];
      List<Group> groups = groupsData.map((groupJson) {
        try {
          return Group.fromJson(groupJson);
        } catch (e) {
          print('Error parsing group: $e');
          return null; // 파싱 오류가 발생한 경우 null 반환
        }
      }).whereType<Group>().toList();

      // 그룹의 관리자 이름을 가져오기
      if (groups.isNotEmpty) {
        final adminName = groups[0].getAdminName();  // 관리자 이름 추출
        print("Admin Name: $adminName");
      }

      return groups;
    } else {
      print('Failed to load groups with status code: ${response.statusCode}');
      return [];
    }
  }
}
