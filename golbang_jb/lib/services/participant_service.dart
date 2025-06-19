import 'dart:developer';
import 'package:get/get.dart';
import 'package:golbang/models/socket/score_card.dart';

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

  Future<ScoreCard?> postStrokeScore({
    required int eventId,
    required int participantId,
    required int holeNumber,
    required int? score
  }) async {
    try {
      const url = '/api/v1/participants/group/stroke/';

      var data = {
        'event_id': eventId,
        'participant_id': participantId,
        'hole_number': holeNumber,
        'score': score
      };

      final response = await privateClient.dio.post(url, data: data);

      if (response.statusCode == 200){
        final jsonData = response.data['data'];
        return ScoreCard.fromJson(jsonData);
      } else {
        log('스코어 입력 실패');
        throw Exception('Error: ${response.printError}');
      }

    } catch (e) {
      log('스코어 입력실패: $e');
      return null;
    }
  }

  Future<List<ScoreCard>?> getGroupScores({required int eventId, required int groupType}) async {
    try {
      const url = '/api/v1/participants/group/stroke/';

      var data = {
        'event_id': eventId,
        'group_type': groupType
      };

      final response = await privateClient.dio.get(url, data: data);

      if (response.statusCode == 200){
        final List<dynamic> jsonList = response.data['data'];
        final List<ScoreCard> groupScores = jsonList
            .map((json) => ScoreCard.fromJson(json))
            .toList();
        return groupScores;
      } else {
        log('스코어 입력 실패');
        throw Exception('Error: ${response.printError}');
      }

    } catch (e) {
      log('스코어 입력실패: $e');
      return null;
    }
  }
}