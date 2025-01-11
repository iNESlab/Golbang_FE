import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../models/profile/member_profile.dart';
import '../repoisitory/secure_storage.dart';

class ClubMemberService {
  final SecureStorage storage;
  final dioClient = DioClient();

  ClubMemberService(this.storage);

  Future<List<ClubMemberProfile>> getClubMemberProfileList({
    required int club_id,
  }) async {

    // API URI 설정
    var uri = "${dotenv.env['API_HOST']}/api/v1/clubs/$club_id/members/";
    // API 요청
    var response = await dioClient.dio.get(uri);;

    // 응답 코드가 200(성공)인지 확인
    if (response.statusCode == 200) {
      // JSON 데이터 파싱
      return (response.data['data'] as List)
          .map((json) => ClubMemberProfile.fromJson(json))
          .toList();

    } else {
      // 오류 발생 시 예외를 던짐
      throw Exception('Failed to load user profiles');
    }
  }
}