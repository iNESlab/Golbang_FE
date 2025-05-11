import 'dart:developer';
import '../global/PrivateClient.dart';
import '../repoisitory/secure_storage.dart';

class ParticipantService {
  final SecureStorage storage;
  final privateClient = PrivateClient();
  
  ParticipantService(this.storage);

  // API 테스트 성공
  Future<bool> updateParticipantStatus(int participantId, String statusType) async {
    try {
      final url =
          '/api/v1/participants/$participantId/?status_type=$statusType';
      final response = await privateClient.dio.patch(url,);

      if (response.statusCode == 200) {
        return true;
      } else {
        log('참석 여부 수정 실패: ${response.statusCode} - ${response.data}');
        log('/participants/$participantId/?status_type=$statusType');

        return false;
      }
    } catch (e) {
      log('Error occurred while updating participant status: $e');
      return false;
    }
  }
}