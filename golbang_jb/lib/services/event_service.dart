import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/models/create_participant.dart';
import '../global/PrivateClient.dart';
import '../models/create_event.dart';
import '../models/responseDTO/GolfClubResponseDTO.dart';
import '../repoisitory/secure_storage.dart';
import '../models/event.dart';
import '../utils/safe_dio_call.dart';

class EventService {
  final SecureStorage storage;
  final privateClient = PrivateClient();

  EventService(this.storage);

  // API 테스트 완료
  Future<List<GolfClubResponseDTO>> getLocationList() async {
    try {
      // URL 생성
      String url = '/api/v1/golfcourses/';

      // API 요청
      final response = await privateClient.dio.get(
        url,
      );

      if (response.statusCode == 200) {
        return GolfClubResponseDTO.fromJsonList(response.data);
      } else {
        log('골프장 목록 조회 실패: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      log('Error occurred while fetching events: $e');
      return [];
    }
  }

  // API 테스트 완료
  Future<GolfClubResponseDTO> getGolfCourseDetails({
    required int golfClubId,
  }) async {
    try {
      // URL 생성
      String url = '/api/v1/golfcourses/?golfclub_id=$golfClubId';

      // API 요청
      final response = await privateClient.dio.get(
        url,
      );
      log('response $response');
      if (response.statusCode == 200) {
        return GolfClubResponseDTO.fromJson(response.data['data']);
      } else {
        throw Exception('상세 조회 실패');
      }
    }
    catch (error, stackTrace) {
      log("❌ 골프장 데이터 요청 실패: $error");
      log("📝 StackTrace: $stackTrace");
      throw Exception('상세 조회 실패');

    }
  }

  // API 테스트 완료
  Future<void> postEvent({
    required int clubId,
    required CreateEvent event,
    required List<CreateParticipant> participants,
  }) async {
    return await safeDioCall<void>(() async {
      final url = '/api/v1/events/?club_id=$clubId';

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
      await privateClient.dio.post(
        url,
        data: requestBody, // dio에서 json으로 바꿔주므로 jsonEncode 안써도 됨
      );
    });
  }

  // API 테스트 완료
  Future<List<Event>> getEventsForMonth({String? date, String? statusType}) async {
    return await safeDioCall<List<Event>>(() async {
      // URL 생성
      String url = '/api/v1/events/';

      // API 요청
      final response = await privateClient.dio.get(
        url,
        queryParameters: {
          if (date != null) 'date': date,
          if (statusType != null) 'status_type': statusType,
        },
      );

        final responseList = response.data['data'] as List;
        return responseList.map((json) => Event.fromJson(json)).toList();
    }) ?? [];
  }

  // API 테스트 완료
  // 이벤트 수정 메서드
  Future<void> updateEvent({
    required CreateEvent event,
    required List<CreateParticipant> participants,
  }) async {
    return await safeDioCall<void>(() async {
      final url = '/api/v1/events/${event.eventId}/';

      // Event의 JSON과 참가자 리스트의 JSON을 각각 생성
      Map<String, dynamic> eventJson = event.toJson();
      List<Map<String, dynamic>> participantsJson =
      participants.map((p) => p.toJson()).toList();

      // 두 개의 데이터를 하나의 Map으로 병합
      Map<String, dynamic> requestBody = {
        ...eventJson, // Event의 데이터를 추가
        'participants': participantsJson, // 참가자 데이터를 추가
      };

      await privateClient.dio.put(
        url,
        data: requestBody,
      );
    });
  }

  // API 테스트 완료
  // 이벤트 종료 메서드
  Future<bool?> endEvent(int eventId) async {
    return await safeDioCall<bool>(() async {
      // API URL 설정
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/');

      // API 요청
      await privateClient.dio.patchUri(url);
      // JSON 데이터를 Event 객체로 변환
      return true;
    });
  }

  // API 테스트 완료
  // 이벤트 삭제 메서드
  Future<void> deleteEvent(int eventId) async {
    return await safeDioCall<void>(() async {
      final url = '/api/v1/events/$eventId/';
      await privateClient.dio.delete(url);
    });
  }

  // 이벤트 개인전 결과 조회
  // 개인전 결과 조회 메서드
  // API 테스트 완료
  Future<Map<String, dynamic>?> getIndividualResults(int eventId, {String? sortType}) async {
    try {
      // Uri 생성 시 sortType이 있을 때만 추가
      final url = Uri.parse('/api/v1/events/$eventId/individual-results/')
          .replace(queryParameters: sortType != null ? {'sort_type': sortType} : null);

      final response = await privateClient.dio.getUri(url);

      if (response.statusCode == 200) {
        log("개인전 결과 조회 성공: ${response.data['data']}");
        return response.data['data'];
      } else {
        log('개인전 결과 조회 실패: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      log('Error occurred while fetching individual results: $e');
      return null;
    }
  }
  //TODO: 테스트
  // 이벤트 팀전 결과 조회
  Future<Map<String, dynamic>?> getTeamResults(int eventId, {String? sortType}) async {
    try {
      // Uri 생성 시 sortType이 있을 때만 추가
      final url = Uri.parse('/api/v1/events/$eventId/team-results/')
          .replace(queryParameters: sortType != null ? {'sort_type': sortType} : null);

      final response = await privateClient.dio.getUri(url);

      if (response.statusCode == 200) {
        log("팀전 결과 조회 성공: ${response.data['data']}");
        log("url $url");
        return response.data['data'];
      } else {
        log('팀전 결과 조회 실패: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      log('Error occurred while fetching team results: $e');
      return null;
    }
  }

  //TODO: 테스트
  // 이벤트 팀전 결과 조회
  // 이벤트 스코어카드 결과 조회 메서드
  Future<Map<String, dynamic>?> getScoreData(int eventId) async {
    try {
      // API URL 설정
      final url = Uri.parse('/api/v1/events/$eventId/scores/');

      // API 요청
      final response = await privateClient.dio.getUri(url);

      if (response.statusCode == 200) {
        // 응답이 200이면 데이터를 파싱하여 반환
        log("========스코어카드 데이터 조회 성공: ${response.data['data']}");
        return response.data['data'];
      } else {
        // 오류 발생 시 로그 출력
        log('스코어카드 조회 실패: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      // 예외 처리
      log('Error occurred while fetching score data: $e');
      return null;
    }
  }
  // API 테스트 완료
  Future<Event?> getEventDetails(int eventId) async {
    return await safeDioCall<Event?>(() async {
        // API URL 설정
        final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/');

        // API 요청
        final response = await privateClient.dio.getUri(url);
        // JSON 데이터를 Event 객체로 변환
        return Event.fromJson(response.data['data']);
    });
  }
}
