class MemberProfileDto {
  // final int memberId;
  final int name;
  final String profileImage;

  MemberProfileDto({ required this.name, required this.profileImage});

  factory MemberProfileDto.toJson(Map<String, dynamic> json) {
    return MemberProfileDto(
        name: json['name'],
        profileImage: json['profile_image'] ?? '');
  }
}

class ReadParticipantRankResponseDto {
  final MemberProfileDto memberProfileDto;
  final int participantId;
  final int lastHoleNumber;
  final int lastScore;
  final String rank;
  final String handicapRank;
  final int sumScore;
  final int handicapScore;

  ReadParticipantRankResponseDto({
    required this.memberProfileDto,
    required this.participantId,
    required this.lastHoleNumber,
    required this.lastScore,
    required this.rank,
    required this.handicapRank,
    required this.sumScore,
    required this.handicapScore,
  });

  // fromJson 메서드: JSON 데이터를 Rank 객체로 변환
  factory ReadParticipantRankResponseDto.fromJson(Map<String, dynamic> json) {
    return ReadParticipantRankResponseDto(
      memberProfileDto: MemberProfileDto.toJson(json['user']), //TODO: 향후 member로 변경
      participantId: json['participant_id'],
      lastHoleNumber: json['last_hole_number'] ?? 99,
      lastScore: json['last_score'] ?? 99,
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      sumScore: json['sum_score'] ?? 99,
      handicapScore: json['handicap_score'] ?? 99,
    );
  }
}
