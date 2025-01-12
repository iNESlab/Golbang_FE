import 'dart:developer';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/models/create_participant.dart';
import 'package:http/http.dart' as http;
import '../global/LoginInterceptor.dart';
import '../models/create_event.dart';
import '../repoisitory/secure_storage.dart';
import '../models/event.dart';

class EventService {
  final SecureStorage storage;
  final dioClient = DioClient();

  EventService(this.storage);

  Future<bool> postEvent({
    required int clubId,
    required CreateEvent event,
    required List<CreateParticipant> participants,
  }) async {
    try {
      final url = '${dotenv.env['API_HOST']}/api/v1/events/?club_id=$clubId';

      // Event의 JSON과 참가자 리스트의 JSON을 각각 생성
      Map<String, dynamic> eventJson = event.toJson();
      List<Map<String, dynamic>> participantsJson =
      participants.map((p) => p.toJson()).toList();

      // 두 개의 데이터를 하나의 Map으로 병합
      Map<String, dynamic> requestBody = {
        ...eventJson, // Event의 데이터를 추가
        'participants': participantsJson, // 참가자 데이터를 추가
      };
      // 병합된 데이터를 JSON으로 변환
      final response = await dioClient.dio.post(
        url,
        data: requestBody, // dio에서 json으로 바꿔주므로 jsonEncode 안써도 됨
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e){
        log('Error occurred while fetching events: $e');
        return false;
    }
  }

  Future<List<Event>> getEventsForMonth({String? date, String? statusType}) async {
    try {
      // URL 생성
      String url = '${dotenv.env['API_HOST']}/api/v1/events/';

      // API 요청
      final response = await dioClient.dio.get(
        url,
        queryParameters: {
          if (date != null) 'date': date,
          if (statusType != null) 'status_type': statusType,
        },
      );

      if (response.statusCode == 200) {
        final responseList = response.data['data'] as List;
        return responseList.map((json) => Event.fromJson(json)).toList();
      } else {
        log('이벤트 목록 조회 실패: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      log('Error occurred while fetching events: $e');
      return [];
    }
  }

  // 이벤트 수정 메서드
  Future<bool> updateEvent({
    required CreateEvent event,
    required List<CreateParticipant> participants,
  }) async {
    try {
      final url = '${dotenv.env['API_HOST']}/api/v1/events/${event.eventId}/';

      // Event의 JSON과 참가자 리스트의 JSON을 각각 생성
      Map<String, dynamic> eventJson = event.toJson();
      List<Map<String, dynamic>> participantsJson =
      participants.map((p) => p.toJson()).toList();

      // 두 개의 데이터를 하나의 Map으로 병합
      Map<String, dynamic> requestBody = {
        ...eventJson, // Event의 데이터를 추가
        'participants': participantsJson, // 참가자 데이터를 추가
      };

      final response = await dioClient.dio.put(
        url,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        log("관리자가 아닙니다. 관리자만 수정할 수 있습니다.");
        return false;
      } else {
        log("Failed to update event: ${response.data}");
        return false;
      }
    } catch (e) {
      log('Error occurred while updating event: $e');
      return false;
    }
  }

  // 이벤트 삭제 메서드
  Future<bool> deleteEvent(int eventId) async {
    try {
      final url = '${dotenv.env['API_HOST']}/api/v1/events/$eventId/';

      final response = await dioClient.dio.delete(url);

      if (response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 403) {
        log("관리자가 아닙니다. 관리자만 삭제할 수 있습니다.");
        return false;
      } else {
        log("Failed to delete event: ${response.data}");
        return false;
      }
    } catch (e) {
      log('Error occurred while deleting event: $e');
      return false;
    }
  }

  // 이벤트 개인전 결과 조회
  // 개인전 결과 조회 메서드
  Future<Map<String, dynamic>?> getIndividualResults(int eventId, {String? sortType}) async {
    try {
      // Uri 생성 시 sortType이 있을 때만 추가
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/individual-results/')
          .replace(queryParameters: sortType != null ? {'sort_type': sortType} : null);

      final accessToken = await storage.readAccessToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        log("개인전 결과 조회 성공: $jsonData");
        return jsonData;
      } else {
        log('개인전 결과 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error occurred while fetching individual results: $e');
      return null;
    }
  }


  // 이벤트 팀전 결과 조회
  Future<Map<String, dynamic>?> getTeamResults(int eventId, {String? sortType}) async {
    try {
      // Uri 생성 시 sortType이 있을 때만 추가
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/team-results/')
          .replace(queryParameters: sortType != null ? {'sort_type': sortType} : null);

      final accessToken = await storage.readAccessToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        log("팀전 결과 조회 성공: $jsonData");
        log("url $url");
        return jsonData;
      } else {
        log('팀전 결과 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error occurred while fetching team results: $e');
      return null;
    }
  }

  // 이벤트 스코어카드 결과 조회 메서드
  Future<Map<String, dynamic>?> getScoreData(int eventId) async {
    try {
      // API URL 설정
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/scores/');
      final accessToken = await storage.readAccessToken(); // 저장소에서 액세스 토큰 가져오기

      // API 요청
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // 액세스 토큰을 헤더에 포함
        },
      );

      if (response.statusCode == 200) {
        // 응답이 200이면 데이터를 파싱하여 반환
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        log("========스코어카드 데이터 조회 성공: $jsonData");
        return jsonData;
      } else {
        // 오류 발생 시 로그 출력
        log('스코어카드 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // 예외 처리
      log('Error occurred while fetching score data: $e');
      return null;
    }
  }
  Future<Event?> getEventDetails(int eventId) async {
    try {
      // API URL 설정
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/');
      final accessToken = await storage.readAccessToken(); // 저장소에서 액세스 토큰 가져오기

      // API 요청
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // 액세스 토큰을 헤더에 포함
        },
      );

      if (response.statusCode == 200) {
        // 응답 데이터 파싱
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        log("이벤트 상세 조회 성공: $jsonData");
        // JSON 데이터를 Event 객체로 변환
        return Event.fromJson(jsonData);
      } else {
        // 오류 로그 출력
        log('이벤트 상세 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // 예외 처리
      log('Error occurred while fetching event details: $e');
      return null;
    }
  }

}
