// participant.dart

class Participant {
  final int participantId;
  final String statusType;
  final String teamType;
  final int groupType;
  final int sumScore;
  final int rank;
  final int handicapScore;

  Participant({
    required this.participantId,
    required this.statusType,
    required this.teamType,
    required this.groupType,
    required this.sumScore,
    required this.rank,
    required this.handicapScore,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      participantId: json['participant_id'],
      statusType: json['status_type'],
      teamType: json['team_type'],
      groupType: json['group_type'],
      sumScore: json['sum_score'],
      rank: json['rank'],
      handicapScore: json['handicap_score'],
    );
  }
}
