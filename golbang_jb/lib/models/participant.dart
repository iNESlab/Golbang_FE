import 'member.dart';

class Participant {
  final int participantId;
  late final String statusType;
  final String teamType;
  final int? holeNumber; // nullable로 변경
  final int groupType;
  final int? sumScore; // nullable로 변경
  final String rank;
  final String handicapRank;
  final int handicapScore;
  final Member? member; // member 속성


  Participant({
    required this.participantId,
    required this.statusType,
    required this.teamType,
    this.holeNumber, // nullable이기 때문에 required 제거
    required this.groupType,
    this.sumScore, // nullable이기 때문에 required 제거
    required this.rank,
    required this.handicapRank,
    required this.handicapScore,
    this.member,
  });

  // copyWith 메서드 추가
  Participant copyWith({
    int? sumScore,
    String? rank,
  }) {
    return Participant(
      participantId: participantId,
      statusType: statusType,
      teamType: teamType,
      holeNumber: holeNumber,
      groupType: groupType,
      sumScore: sumScore ?? this.sumScore,
      rank: rank ?? this.rank,
      handicapRank: handicapRank,
      handicapScore: handicapScore,
      member: member,
    );
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      participantId: json['participant_id'] ?? 0,
      statusType: json['status_type'] ?? '',
      teamType: json['team_type'] ?? '',
      holeNumber: json['hole_number'] ?? 0,
      // nullable이므로 기본값 없이 처리
      groupType: json['group_type'] ?? 0,
      sumScore: json['sum_score'],
      // nullable이므로 기본값 없이 처리
      rank: json['rank'] ?? "",
      handicapRank: json['handicap_rank'] ?? "",
      handicapScore: json['handicap_score'] ?? 0,
      member: json['member'] != null ? Member.fromJson(json['member']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participant_id': participantId,
      'status_type': statusType,
      'team_type': teamType,
      'hole_number': holeNumber, // nullable이므로 null이 아닐 때만 포함
      'group_type': groupType,
      'sum_score': sumScore, // nullable이므로 null이 아닐 때만 포함
      'rank': rank,
      'handicap_rank': handicapRank,
      'handicap_score': handicapScore,
    };
  }
}

