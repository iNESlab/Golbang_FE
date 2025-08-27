import '../../domain/entities/event_individual_result.dart';
import '../models/event/responses/read_event_individual_response_dto.dart';

extension MyRecordMapper on MyRecordDto {
  MyRecord toEntity() {
    return MyRecord(
        name: name,
        profileImage: profileImage,
        stroke: stroke, rank: rank,
        handicapRank: handicapRank,
        scores: scores
    );
  }
}

extension IndividualRankResultMapper on IndividualRankResultDto {
  IndividualRankResult toEntity() {
    return IndividualRankResult(
      participantId: participantId,
      statusType: statusType,
      teamType: teamType,
      holeNumber: holeNumber,
      groupType: groupType,
      sumScore: sumScore,
      handicapScore: handicapScore,
      rank: rank,
      handicapRank: handicapRank
    );
  }
}

extension ReadEventIndividualMapper on ReadEventIndividualResponseDto {
  EventIndividualResult toEntity() {
    return EventIndividualResult(
        eventId: eventId,
        eventTitle: eventTitle,
        site: site,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        gameMode: gameMode,
        myRecord: myRecordDto.toEntity(),
        individualRankResults: individualRankResultDtos.map((p)=>p.toEntity()).toList(),
    );
  }
}
