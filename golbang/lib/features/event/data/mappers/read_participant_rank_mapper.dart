import '../../domain/entities/participant_rank.dart';
import '../models/participant/responses/read_participant_rank_response_dto.dart';

extension MemberProfileMapper on MemberProfileDto {
  MemberProfile toEntity() {
    return MemberProfile(name: name, profileImage: profileImage);
  }
}

extension ReadRankResponseMapper on ReadParticipantRankResponseDto {
  ParticipantRank toEventEntity() {
    return ParticipantRank(
      participantId: participantId,
      lastHoleNumber: lastHoleNumber,
      lastScore: lastScore,
      rank: rank,
      handicapRank: handicapRank,
      handicapScore: handicapScore,
      sumScore: sumScore,
      member: memberProfileDto.toEntity(),
    );
  }
}
