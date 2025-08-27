import 'package:golbang/features/event/data/models/participant/responses/read_participant_scores_response_dto.dart';

import '../../domain/entities/participant_scores.dart';

extension ReadParticipantScoresMapper on ReadParticipantScoresResponseDto {
  ParticipantScores toEntity() {
    return ParticipantScores(
        teamType: teamType,
        frontNineScore: frontNineScore,
        backNineScore: backNineScore,
        totalScore: totalScore,
        handicapScore: handicapScore,
        scores: scores
    );
  }
}
