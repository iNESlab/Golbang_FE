// data/repositories/event_repository_impl.dart
import 'package:golbang/features/event/data/mappers/draft_event_input_mapper.dart';
import 'package:golbang/features/event/data/mappers/draft_participant_input_mapper.dart';
import 'package:golbang/features/event/data/mappers/read_event_detail_mapper.dart';
import 'package:golbang/features/event/data/mappers/read_golf_club_mapper.dart';
import 'package:golbang/features/event/data/mappers/read_individual_event_result_mapper.dart';// ← 골프클럽 매퍼가 여기에 있다고 가정
import 'package:golbang/features/event/data/mappers/read_participant_scores_mapper.dart';
import 'package:golbang/features/event/domain/entities/participant_scores.dart';

import '../../domain/entities/event_individual_result.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/golf_club.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/event.dart' show DraftEventInput;            // 네이밍에 맞게 import
import '../../domain/entities/participant.dart' show DraftParticipantInput; // 네이밍에 맞게 import
import '../datasources/event_remote_ds.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._remote);
  final EventRemoteDs _remote;

  // ───────────────────────────────── Event ─────────────────────────────────

  @override
  Future<Event> getEventDetail(int eventId) async {
    final dto = await _remote.fetchEventDetail(eventId);
    return dto.toEventEntity();
  }

  @override
  Future<List<Participant>> getParticipants(int eventId) async {
    final dto = await _remote.fetchEventDetail(eventId);
    return dto.toParticipantEntities();
  }

  @override
  Future<int> createEvent({
    required int clubId,
    required DraftEventInput draftEvent,
    required List<DraftParticipantInput> draftParticipant,
  }) async {
    final createParticipantDtos =
    draftParticipant.map((p) => p.toCreateParticipantReqDto()).toList();

    final createEventDto = draftEvent.toCreateEventReqDto(
      createParticipantRequestDtos: createParticipantDtos,
    );

    final res = await _remote.postEvent(
      clubId: clubId,
      event: createEventDto,
    );
    return res.eventId;
  }

  @override
  Future<void> updateEvent({
    required int eventId,
    required DraftEventInput draftEvent,
    required List<DraftParticipantInput> draftParticipant,
  }) async {
    final updateParticipantDtos =
    draftParticipant.map((p) => p.toUpdateParticipantReqDto()).toList();

    final updateEventDto = draftEvent.toUpdateEventReqDto(
      updateParticipantRequestDtos: updateParticipantDtos,
    );

    await _remote.putEvent(
      eventId: eventId,
      event: updateEventDto,
    );
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    await _remote.deleteEvent(eventId);
  }

  // ───────────────────────────── Results / Scores ─────────────────────────────

  @override
  Future<EventIndividualResult> getIndividualResults(
      int eventId, {
        String? sortType,
      }) async {
    final dto = await _remote.fetchIndividualResults(eventId, sortType: sortType);
    return dto.toEntity(); // mapper: EventIndividualResult
  }

  // @override
  // Future<List<ParticipantRank>> getTeamResults(
  //     int eventId, {
  //       String? sortType,
  //     }) async {
  //   final map = await _remote.fetchTeamResults(eventId, sortType: sortType);
  //   return dto.toEntityList(); // mapper: List<ParticipantRank>
  // }

  @override
  Future<List<ParticipantScores>> getScoreCardResult(int eventId) async {
    final dtos = await _remote.fetchScoreCardResult(eventId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  // ───────────────────────────────── Golf Club ────────────────────────────────

  @override
  Future<List<GolfClubSummary>> getGolfClubs() async {
    final dtos = await _remote.fetchGolfClubs();
    return dtos.map((d) => d.toEntity()).toList(); // mapper: GolfClubSummary
  }

  @override
  Future<GolfClubSummary> getGolfClubSummary(int golfClubId) async {
    final dto = await _remote.fetchGolfClubSummary(golfClubId);
    return dto.toEntity(); // mapper: GolfClubSummary (혹은 Detail 엔티티가 따로면 거기에 맞게)
  }
}