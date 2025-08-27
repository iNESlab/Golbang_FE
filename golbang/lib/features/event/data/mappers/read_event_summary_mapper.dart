import '../../domain/entities/event.dart';
import '../../domain/entities/participant.dart';
import '../models/event/responses/read_event_detail_response_dto.dart';
import '../models/participant/responses/participant_summary_response_dto.dart';

extension ClubMemberProfileMapper on ClubMemberProfileDto {
  ClubMemberProfile toEntity() => ClubMemberProfile(
    clubMemberId: clubMemberId,
    isClubAdmin: isClubAdmin,
    memberId: memberId,
    email: email,
    name: name,
    profileImage: profileImage, // domain은 nullable 이므로 그대로 전달
  );
}

extension ReadEventSummaryResponseMapper on ReadEventDetailResponseDto {
  Event toEventEntity() {
    return Event(
      eventId: eventId,
      eventTitle: eventTitle,
      startDateTime: startDateTime,     // 규칙화: 항상 ISO로 받도록
      endDateTime: endDateTime,
      repeatType: repeatType,
      gameMode: gameMode,
    );
  }

  List<Participant> toParticipantEntities() =>
      (participantSummaryResponseDtos ?? const <ParticipantSummaryResponseDto>[])
          .map((p) => Participant(
        participantId: p.participantId,
        clubMember: p.clubMemberProfileDto.toEntity(),
        teamType: p.teamType,
        statusType: p.statusType,
        groupType: p.groupType,
      )).toList();

  /// 한 번에 받고 싶다면 레코드로 반환
  (Event event, List<Participant> participants) toAggregate() =>
      (toEventEntity(), toParticipantEntities());

}
