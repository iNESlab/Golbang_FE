class ReadRankResponseDto {
  final String userName;
  final String profileImage;
  final int participantId;
  final int lastHoleNumber;
  final int lastScore;
  final String rank;
  final String handicapRank;
  final int sumScore;
  final int handicapScore;

  ReadRankResponseDto({
    required this.userName,
    required this.profileImage,
    required this.participantId,
    required this.lastHoleNumber,
    required this.lastScore,
    required this.rank,
    required this.handicapRank,
    required this.sumScore,
    required this.handicapScore,
  });

  // fromJson 메서드: JSON 데이터를 Rank 객체로 변환
  factory ReadRankResponseDto.fromJson(Map<String, dynamic> json) {
    return ReadRankResponseDto(
      userName: json['user']['name'],
      profileImage: json['user']['profile_image'] ?? '',
      participantId: json['participant_id'],
      lastHoleNumber: json['last_hole_number'],
      lastScore: json['last_score'],
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      sumScore: json['sum_score'],
      handicapScore: json['handicap_score'],
    );
  }
}
