class ClubMemberProfileDto {
  // clubMember 정보
  final int clubMemberId;
  final bool isClubAdmin;
  // final bool role;
  // 유저 정보
  final int memberId; // accountId 로 스프링과 통일
  final String email;
  final String name;
  final String profileImage;

  ClubMemberProfileDto({
    required this.clubMemberId,
    required this.isClubAdmin,
    required this.memberId,
    required this.email,
    required this.name,
    required this.profileImage
  }); // profileImage

  factory ClubMemberProfileDto.fromJson(Map<String, dynamic> json) {
    return ClubMemberProfileDto(
      clubMemberId: json['member_id'], //TODO: club_member_id로 서버에서 수정해야함
      isClubAdmin: json['is_current_user_admin'], //TODO: is_current_user_admin => is_club_admin으로 서버 수정해야함
      memberId: json['user']['id'], // TODO: 스프링에서 member로 그리고, id가 아닌 member_id로 응답해야함
      email: json['email'],
      name: json['user']['name'],
      profileImage: json['profile_image']??'',
    );
  }
}

class HoleScoreResponseDto {
  // final int holeId;
  final int holeNumber;
  final int score;

  HoleScoreResponseDto({
    // reuired this.holeId,
    required this.holeNumber,
    required this.score,
  });

  factory HoleScoreResponseDto.fromJson(Map<String, dynamic> json) {
    return HoleScoreResponseDto(
      // holeId: json['hole_id'] as int,
      holeNumber: json['hole_number'] as int,
      score: json['score'] as int,
    );
  }
}