//TODO: 노션 API 명세서랑 달라서 체크해야함

// 참가자 리스트 조회시 사용되는 Dto
import 'package:golbang/features/event/domain/enum/event.dart';

class ClubMemberProfileDto {
  // clubMember 정보
  final int clubMemberId;
  final bool isClubAdmin;
  // final bool role;
  // 유저 정보
  final int memberId; // 유저 Id 스프링과 통일
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
      profileImage: json['profile_image'],
    );
  }
}

class ParticipantSummaryResponseDto {
  final int participantId;
  final ClubMemberProfileDto clubMemberProfileDto;
  final String statusType;
  final TeamConfig teamType;
  final int holeNumber;
  final int groupType;
  final int sumScore;
  final String rank;
  final String handicapRank;
  final int handicapScore;

  ParticipantSummaryResponseDto({
    required this.participantId,
    required this.clubMemberProfileDto,
    required this.statusType,
    required this.teamType,
    required this.holeNumber,
    required this.groupType,
    required this.sumScore,
    required this.rank,
    required this.handicapRank,
    required this.handicapScore
  });

  factory ParticipantSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return ParticipantSummaryResponseDto(
      participantId: json['participant_id'],
      clubMemberProfileDto: ClubMemberProfileDto.fromJson(json['member']), //TODO: member => clubMember로 수정해야함
      statusType: json['status_type'],
      teamType: TeamConfig.values.firstWhere((e) => e.value == json['team_type']),
      holeNumber: json['hole_number'],
      groupType: json['group_type'],
      sumScore: json['sum_score'],
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      handicapScore: json['handicap_score'],
    );
  }

}