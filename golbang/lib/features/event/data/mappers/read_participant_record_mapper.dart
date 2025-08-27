import 'package:golbang/features/event/data/models/participant/responses/hole_score_response_dto.dart';
import 'package:golbang/features/event/domain/entities/hole_score.dart';

import '../../domain/entities/participant_rank.dart';
import '../../domain/entities/participant_record.dart';
import '../models/participant/responses/read_participant_record_response_dto.dart';
import '../models/participant/responses/read_participant_rank_response_dto.dart';

extension MemberProfileMapper on MemberProfileDto {
  MemberProfile toEntity() {
    return MemberProfile(name: name, profileImage: profileImage);
  }
}

extension HoleScoreResponseMapper on HoleScoreResponseDto {
  HoleScore toEntity() {
    return HoleScore(holeNumber: holeNumber, score: score);
  }
}

extension ReadParticipantRecordResponseMapper on ReadParticipantRecordResponseDto {
  ParticipantRecord toEntity() {
    return ParticipantRecord(
      participantId: participantId,
      memberName: memberName,
      teamType: teamType,
      groupType: groupType,
      sumScore: sumScore,
      handicapScore: handicapScore,
      holeScores: holeScores.map((s) => s.toEntity()).toList(),
    );
  }
}
