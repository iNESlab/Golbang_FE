// 컨벤션
// 1. 함수명: fetch(get X), post, delete, put 사용하기
// 2. safeDioCall로 보내기 (여기서 에러 핸들링)
// 3. dynamic으로 return 하지 말기

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:golbang/features/event/data/models/participant/requests/create_participant_request_dto.dart';
import '../../../../core/network/PrivateClient.dart';
import '../models/event/requests/create_event_request_dto.dart';
import '../models/golf_club/responses/golf_club_summary_response_dto.dart';
import '../../../../core/network/safe_dio_call.dart';
import '../models/event/responses/create_event_response_dto.dart';
import '../models/event/responses/read_event_detail_response_dto.dart';
import '../models/event/responses/read_event_summary_response_dto.dart';
import '../models/event/requests/update_event_request_dto.dart';

class EventRemoteDs {
  // final SecureStorage storage;
  final PrivateClient _client;
  EventRemoteDs(this._client);

  // GET
  Future<List<GolfClubSummaryResponseDto>> fetchGolfClubs() =>
      safeDioCall(() async {
        final res = await _client.dio.get('/api/v1/golfcourss/');
        final list = (res.data['data'] as List?) ?? [];
        return list.map((j) => GolfClubSummaryResponseDto.fromJson(j)).toList();
      });

  Future<GolfClubSummaryResponseDto> fetchGolfClubDetail(int golfClubId) =>
      safeDioCall(() async {
        final res = await _client.dio.get('/api/v1/golfcourses/', queryParameters: {
          'golfclub_id': golfClubId,
        });
        return GolfClubSummaryResponseDto.fromJson(res.data['data']);
  });

  // API 테스트 완료
  Future<List<ReadEventSummaryResponseDto>> fetchEventsForMonth({String? date, String? statusType})  =>
    safeDioCall(() async {
      final response = await _client.dio.get(
        '/api/v1/events/',
        queryParameters: {
          if (date != null) 'date': date,
          if (statusType != null) 'status_type': statusType,
        },
      );
      final responseList = response.data['data'] as List;
      return responseList.map((json) => ReadEventSummaryResponseDto.fromJson(json)).toList();
  });

  // 이벤트 개인전 결과 조회
  Future<Map<String, dynamic>> fetchIndividualResults(int eventId, {String? sortType}) =>
      safeDioCall(() async{
    final url = Uri.parse('/api/v1/events/$eventId/individual-results/')
        .replace(queryParameters: sortType != null ? {'sort_type': sortType} : null);
    final res = await _client.dio.getUri(url);
    return res.data['data'];
  });

  //TODO: 테스트
  // 이벤트 팀전 결과 조회
  Future<Map<String, dynamic>> fetchTeamResults(int eventId, {String? sortType}) =>
      safeDioCall(() async{
    final url = Uri.parse('/api/v1/events/$eventId/team-results/')
        .replace(queryParameters: sortType != null ? {'sort_type': sortType} : null);
    final res = await _client.dio.getUri(url);
    return res.data['data'];
  });

  //TODO: 테스트
  // 이벤트 스코어카드 결과 조회 메서드
  Future<Map<String, dynamic>> fetchScoreData(int eventId) =>
      safeDioCall(() async{
    final res = await _client.dio.get('/api/v1/events/$eventId/scores/');
    return res.data['data'];
  });

  // API 테스트 완료
  Future<ReadEventDetailResponseDto> fetchEventDetail(int eventId) =>
      safeDioCall(() async{
    final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/$eventId/');
    final res = await _client.dio.getUri(url);
    return ReadEventDetailResponseDto.fromJson(res.data['data']);
  });

  // POST
  Future<PostEventResponseDto> postEvent({
    required int clubId,
    required CreateEventRequestDto event,
    required List<CreateParticipantRequestDto> participants,
  }) => safeDioCall(() async {
      final body = {
        ...event.toJson(),
        'participants': participants.map((p) => p.toJson()).toList(),
      };
      final res = await _client.dio.post('/api/v1/events/', queryParameters: {
        'club_id': clubId,
      }, data: body);
      return PostEventResponseDto.fromJson(res.data['data']);
    });

  // PUT
  Future<void> putEvent({
    required int eventId,
    required UpdateEventRequestDto event,
  }) => safeDioCall(() async {
    final body = {...event.toJson(), 'participants': event.updateParticipantRequestDtos.map((p) => p.toJson()).toList()};
    await _client.dio.put('/api/v1/events/$eventId/', data: body);
  });

  // DELETE
  Future<void> deleteEvent(int eventId) => safeDioCall(() async {
    await _client.dio.delete('/api/v1/events/$eventId/');
  });

}
