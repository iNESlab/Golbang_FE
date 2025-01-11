import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../repoisitory/secure_storage.dart';

class ParticipantService {
  final SecureStorage storage;
  final dioClient = DioClient();
  
  ParticipantService(this.storage);

  Future<bool> updateParticipantStatus(int participantId, String statusType) async {
    try {
      final url =
          '${dotenv.env['API_HOST']}/api/v1/participants/$participantId/?status_type=$statusType';
      final response = await dioClient.dio.patch(url,);

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