import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/models/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart'; // basename을 사용하기 위해 필요
import '../repoisitory/secure_storage.dart';

class GroupService {
  final SecureStorage storage;

  GroupService(this.storage);

  Future<bool> saveGroup({
    required String name,
    required String description,
    required List<UserProfile> members,
    required List<UserProfile> admins,
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
        print('Failed to create group. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
