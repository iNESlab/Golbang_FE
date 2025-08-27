import 'package:golbang/features/event/domain/entities/event_individual_result.dart';
import 'package:golbang/features/event/domain/entities/participant_scores.dart';

import '../entities/event.dart';
import '../entities/golf_club.dart';
import '../entities/participant.dart';

abstract class EventRepository {
  Future<Event> getEventDetail(int eventId);
  Future<List<Participant>> getParticipants(int eventId);
  Future<int> createEvent({
    required int clubId,
    required DraftEventInput draftEvent,
    required List<DraftParticipantInput> draftParticipant
  });
  Future<void> updateEvent({
    required int eventId,
    required DraftEventInput draftEvent,
    required List<DraftParticipantInput> draftParticipant
  });
  Future<void> deleteEvent(int eventId);

  // 결과/스코어 (도메인 엔티티로!)
  Future<EventIndividualResult> getIndividualResults(int eventId, {String? sortType});
  // Future<List<ParticipantRank>> getTeamResults(int eventId, {String? sortType});
  Future<List<ParticipantScores>> getScoreCardResult(int eventId);

  // 골프클럽
  Future<List<GolfClubSummary>> getGolfClubs();
  Future<GolfClubSummary> getGolfClubSummary(int golfClubId);
}