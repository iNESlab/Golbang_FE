import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../repoisitory/secure_storage.dart';

class ParticipantService {
  final SecureStorage storage;

  ParticipantService(this.storage);

  Future<bool> updateParticipantStatus(int participantId, String statusType) async {
    try {
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/participants/$participantId/?status_type=$statusType');
      final accessToken = await storage.readAccessToken();
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        print('참석 여부 수정 성공: ${response.body}');
        return true;
      } else {
        print('참석 여부 수정 실패: ${response.statusCode} - ${response.body}');
        print('/participants/$participantId/?status_type=$statusType');

        return false;
      }
    } catch (e) {
      print('Error occurred while updating participant status: $e');
      return false;
    }
  }
}