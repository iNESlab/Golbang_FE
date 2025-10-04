import 'dart:developer';
import 'package:golbang/models/socket/score_card.dart';

import '../global/PrivateClient.dart';
import '../repoisitory/secure_storage.dart';
import '../utils/safe_dio_call.dart';

class ParticipantService {
  final SecureStorage storage;
  final privateClient = PrivateClient();
  
  ParticipantService(this.storage);

  // API 테스트 성공
  Future<void> updateParticipantStatus(int participantId, String statusType) async {
    return await safeDioCall<void>(() async {
      final url =
          '/api/v1/participants/$participantId/?status_type=$statusType';
       await privateClient.dio.patch(url,);
    });
  }

  Future<ScoreCard?> postStrokeScore({
    required int eventId,
    required int participantId,
    required int holeNumber,
    required int? score,
  }) async {
    return await safeDioCall<ScoreCard?>(() async {
      const url = '/api/v1/participants/group/stroke/';

      final data = {
        'event_id': eventId,
        'participant_id': participantId,
        'hole_number': holeNumber,
        'score': score,
      };

      final response = await privateClient.dio.post(url, data: data);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final jsonData = response.data['data'];
        if (jsonData == null) {
          return null;
        }
        return ScoreCard.fromJson(jsonData);
      } else {
        final errorMsg = response.data['message'] ??
            response.data['error'] ??
            response.statusMessage ??
            '알 수 없는 서버 오류입니다';
        throw Exception('에러: ${response.statusCode}\n메시지: $errorMsg');
      }
    });
  }


  Future<List<ScoreCard>?> getGroupScores({
    required int eventId,
    required int groupType,
  }) async {
    return await safeDioCall(() async {
      const url = '/api/v1/participants/group/stroke/';
      final data = {
        'event_id': eventId,
        'group_type': groupType,
      };

      final response = await privateClient.dio.get(url, data: data);

      final List<dynamic> jsonList = response.data['data'];
      return jsonList.map((json) => ScoreCard.fromJson(json)).toList();
    });
  }
}