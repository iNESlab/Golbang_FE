import 'package:golbang/features/event/domain/enum/event_enum.dart';

class ReadParticipantScoresResponseDto {
  // final int participantId;
  final TeamConfig teamType;
  final int frontNineScore;
  final int backNineScore;
  final int totalScore;
  final int handicapScore;
  final List<int?> scores;

  ReadParticipantScoresResponseDto({
    required this.teamType,
    required this.frontNineScore,
    required this.backNineScore,
    required this.totalScore,
    required this.handicapScore,
    required this.scores
  });

  factory ReadParticipantScoresResponseDto.fromJson(Map<String, dynamic> json) {
    return ReadParticipantScoresResponseDto(
        teamType: json['team'], // TODO: team_type으로 서버 수정해야함
        frontNineScore: json['front_nine_score'] ?? 99,
        backNineScore: json['back_nine_score'] ?? 99,
        totalScore: json['total_score'] ?? 99,
        handicapScore: json['handicap_score'] ?? 99,
        scores: (json['scorecard'] as List<dynamic>?)
            ?.map((e) => e == null ? null : e as int).toList()
            ?? <int?>[],
    );
  }

}