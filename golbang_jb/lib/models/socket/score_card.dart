import 'package:golbang/models/hole_score.dart';

class ScoreCard {
  final int participantId;
  final String? userName;
  final int groupType;
  final String teamType;
  final bool isGroupWin;
  final bool isGroupWinHandicap;
  final int? sumScore; // nullable로 변경
  final int handicapScore;

  final List<HoleScore>? scores;

  ScoreCard({
    required this.participantId,
    this.userName,
    required this.teamType,
    required this.groupType,
    required this.isGroupWin,
    required this.isGroupWinHandicap,
    this.sumScore, // nullable이기 때문에 required 제거
    required this.handicapScore,
    this.scores
  });

  factory ScoreCard.fromJson(Map<String, dynamic> json) {
    return ScoreCard(
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
          ?.map((scoreJson) => HoleScore.fromJson(scoreJson))
          .toList(),
    );
  }

}

