
import '../../../../domain/enum/event_enum.dart';

class UpdateParticipantRequestDto {
  final int memberId;
  final TeamConfig teamType;
  final int groupType;

  UpdateParticipantRequestDto({
    required this.memberId,
    required this.teamType,
    required this.groupType,
  });

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'team_type': teamType.value,
      'group_type': groupType,
    };
  }
}