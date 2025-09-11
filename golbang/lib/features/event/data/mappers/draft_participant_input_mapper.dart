import '../../domain/entities/participant.dart';
import '../models/participant/requests/create_participant_request_dto.dart';
import '../models/participant/requests/update_participant_request_dto.dart';

extension DraftParticipantInputMapper on DraftParticipantInput {
  CreateParticipantRequestDto toCreateParticipantReqDto() => CreateParticipantRequestDto(
      memberId: memberId,
      teamType: teamType,
      groupType: groupType
  );

  UpdateParticipantRequestDto toUpdateParticipantReqDto() => UpdateParticipantRequestDto(
      memberId: memberId,
      teamType: teamType,
      groupType: groupType
  );
}