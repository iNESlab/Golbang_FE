// models/participant.dart
// 이벤트 참여자

class Participant {
  final String teamType;
  final int groupType;
  final int sumScore;
  final int handicapScore;
  final String rank;
  final String handicapRank;
  final int points;
  final String statusType;

  Participant({
    required this.teamType,
    required this.groupType,
    required this.sumScore,
    required this.handicapScore,
    required this.rank,
    required this.handicapRank,
    required this.points,
    required this.statusType,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      teamType: json['team_type'],
      groupType: json['group_type'],
      sumScore: json['sum_score'],
      handicapScore: json['handicap_score'],
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      points: json['points'],
      statusType: json['status_type'],
    );
  }
}
