import '../core/network/PrivateClient.dart';
import '../models/profile/member_profile.dart';
import '../repoisitory/secure_storage.dart';

class ClubMemberService {
  final SecureStorage storage;
  final privateClient = PrivateClient();

  ClubMemberService(this.storage);

  // API 테스트 완료
  Future<List<ClubMemberProfile>> getClubMemberProfileList({
    required int clubId,
  }) async {

    // API URI 설정
    var uri = "/api/v1/clubs/$clubId/members/";
    // API 요청
    var response = await privateClient.dio.get(uri);

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