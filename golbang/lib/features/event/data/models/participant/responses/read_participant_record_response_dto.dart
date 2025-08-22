// 구: scorecard

import 'package:golbang/features/event/data/models/golf_club/responses/hole_score_response_dto.dart';
import 'package:golbang/features/event/domain/enum/event.dart';

class ReadParticipantRecordResponseDto {
  final int participantId;
  final String userName;
  final String groupType;
  final TeamConfig teamType;
  final bool isGroupWin;
  final bool isGroupWinHandicap;
  final int? sumScore; // nullable로 변경
  final int handicapScore;

  final List<HoleScoreResponseDto>? scores;

  ReadParticipantRecordResponseDto({
    required this.participantId,
    required this.userName,
    required this.teamType,
    required this.groupType,
    required this.isGroupWin,
    required this.isGroupWinHandicap,
    this.sumScore, // nullable이기 때문에 required 제거
    required this.handicapScore,
    this.scores
  });

  factory ReadParticipantRecordResponseDto.fromJson(Map<String, dynamic> json) {
    return ReadParticipantRecordResponseDto(
      participantId: json['participant_id'] ?? 0,
      userName: json['user_name'] ?? 'unknown',
      teamType: json['team_type'] ?? 'NONE',
      // nullable이므로 기본값 없이 처리
      groupType: json['group_type'] ?? 0,
      isGroupWin: json['is_group_win'] ?? false,
      isGroupWinHandicap: json['is_group_win_handicap'] ?? false,
      sumScore: json['sum_score'],
      // nullable이므로 기본값 없이 처리
      handicapScore: json['handicap_score'] ?? 0,
      scores: (json['scores'] as List<dynamic>?)
          ?.map((scoreJson) => HoleScoreResponseDto.fromJson(scoreJson))
          .toList() ?? [],
    );
  }

}

