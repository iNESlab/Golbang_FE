import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/models/create_participant.dart';
import 'package:http/http.dart' as http;
import '../models/create_event.dart';
import '../repoisitory/secure_storage.dart';
import '../models/event.dart';

class EventService {
  final SecureStorage storage;

  EventService(this.storage);

  Future<bool> postEvent({
    required int clubId,
    required CreateEvent event,
    required List<CreateParticipant> participants,
  }) async {
    try {
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/?club_id=$clubId');
      final accessToken = await storage.readAccessToken();

      // Event의 JSON과 참가자 리스트의 JSON을 각각 생성
      Map<String, dynamic> eventJson = event.toJson();
      List<Map<String, dynamic>> participantsJson =
      participants.map((p) => p.toJson()).toList();

      // 두 개의 데이터를 하나의 Map으로 병합
      Map<String, dynamic> requestBody = {
        ...eventJson, // Event의 데이터를 추가
        'participants': participantsJson, // 참가자 데이터를 추가
      };
      print('requestBody: $requestBody');
      // 병합된 데이터를 JSON으로 변환
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody), // JSON 데이터를 전송
      );

      if (response.statusCode == 201) {
        print("Event created successfully");
        return true;
      } else {
        print("Failed to create event: ${response.body}");
        return false;
      }
    } catch (e){
        print('Error occurred while fetching events: $e');
        return false;
    }
  }

  Future<List<Event>> getEventsForMonth({String? date, String? statusType}) async {
    try {
      // API URL 설정
      //final url = Uri.parse('${dotenv.env['API_HOST']}/events/?date=${date ?? DateTime.now().toIso8601String()}&status_type=');
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/');

      // 액세스 토큰 가져오기
      final accessToken = await storage.readAccessToken();

      // API 요청
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes))['data'] as List;
        print("이벤트 목록 조회 성공: ${jsonData.length}개");
        // JSON 데이터를 Event 객체 리스트로 변환
        print(jsonData);


        return jsonData.map((json) => Event.fromJson(json)).toList();
      } else {
        print('이벤트 목록 조회 실패: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error occurred while fetching events: $e');
      return [];
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
        print("개인전 결과 조회 성공: $jsonData");
        return jsonData;
      } else {
        print('개인전 결과 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching individual results: $e');
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
        print("팀전 결과 조회 성공: $jsonData");
        print("url $url");
        return jsonData;
      } else {
        print('팀전 결과 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching team results: $e');
      return null;
    }
  }

}
