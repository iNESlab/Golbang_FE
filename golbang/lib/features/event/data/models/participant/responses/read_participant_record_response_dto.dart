// 구: scorecard

import 'package:golbang/features/event/data/models/participant/responses/hole_score_response_dto.dart';
import 'package:golbang/features/event/domain/enum/event_enum.dart';

class ReadParticipantRecordResponseDto {
  final int participantId;
  final String memberName;
  final int groupType;
  final TeamConfig teamType;
  final bool isGroupWin;
  final bool isGroupWinHandicap;
  final int sumScore; // nullable로 변경
  final int handicapScore;

  final List<HoleScoreResponseDto> holeScores;

  ReadParticipantRecordResponseDto({
    required this.participantId,
    required this.memberName,
    required this.teamType,
    required this.groupType,
    required this.isGroupWin,
    required this.isGroupWinHandicap,
    required this.sumScore, // nullable이기 때문에 required 제거
    required this.handicapScore,
    required this.holeScores
  });

  factory ReadParticipantRecordResponseDto.fromJson(Map<String, dynamic> json) {
    return ReadParticipantRecordResponseDto(
      participantId: json['participant_id'],
      memberName: json['user_name'] ?? 'unknown',
      teamType: TeamConfigX.fromString(json['team_type'] as String),
      groupType: json['group_type'],
      isGroupWin: json['is_group_win'] ?? false,
      isGroupWinHandicap: json['is_group_win_handicap'] ?? false,
      sumScore: json['sum_score'] ?? 99,
      handicapScore: json['handicap_score'] ?? 99,
      holeScores: (json['scores'] as List<dynamic>?)
          ?.map((scoreJson) => HoleScoreResponseDto.fromJson(scoreJson))
          .toList() ?? [],
    );
  }

}

