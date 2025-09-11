class MemberProfile {
  // inal int memberId;
  final int name;
  final String profileImage;

  MemberProfile({ required this.name, required this.profileImage});
}

class ParticipantRank{
  final int participantId;
  final int lastHoleNumber;
  final int lastScore;
  final String rank;
  final String handicapRank;
  final int sumScore;
  final int handicapScore;
  final MemberProfile member;

  ParticipantRank({
    required this.participantId,
    required this.lastHoleNumber,
    required this.lastScore,
    required this.rank,
    required this.handicapRank,
    required this.sumScore,
    required this.handicapScore,
    required this.member
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParticipantRank && other.participantId == participantId;
  }

  @override
  int get hashCode => participantId.hashCode;

}