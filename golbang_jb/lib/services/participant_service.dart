import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../repoisitory/secure_storage.dart';

class ParticipantService {
  final SecureStorage storage;

  ParticipantService(this.storage);

  // 특정 참가자의 참석 여부를 수정하는 메서드
  Future<void> updateParticipantStatus(int participantId, String statusType) async {
    try {
      final url = Uri.parse('${dotenv.env['API_HOST']}/participants/$participantId/');
      final accessToken = await storage.readAccessToken();
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'status_type': statusType}),
      );

      if (response.statusCode == 200) {
        print('참석 여부 수정 성공: ${response.body}');
      } else {
        print('참석 여부 수정 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error occurred while updating participant status: $e');
    }
  }
}