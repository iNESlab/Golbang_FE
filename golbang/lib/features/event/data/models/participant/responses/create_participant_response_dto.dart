import '../../../../domain/enum/event.dart';

class UpdateParticipantResponseDto {
  final int participantId;
  final int memberId;
  final int eventId;
  final TeamConfig teamType;
  final int groupType;
  final String statusType;
  // final int sumScore;
  // final String rank;
  // final String handicapRank;

  UpdateParticipantResponseDto({
    required this.participantId,
    required this.memberId,
    required this.eventId,
    required this.teamType,
    required this.groupType,
    required this.statusType,
  });

  factory UpdateParticipantResponseDto.fromJson(Map<String, dynamic> json) {
    return UpdateParticipantResponseDto(
      participantId: json['participant_id'],
      memberId: json['member_id'],
      eventId: json['event_id'],
      teamType: TeamConfig.values.firstWhere((e) => e.value == json['team_type']),
      groupType: json['group_type'],
      statusType: json['status_type']
    );
  }
}