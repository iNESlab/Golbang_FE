// 이벤트 상세에서 필요한 참가자 정보

import '../enum/event_enum.dart';

class ClubMemberProfile {
  // clubMember 정보
  final int clubMemberId;
  final bool isClubAdmin;
  // final bool role;
  // 유저 정보
  final int memberId; // 유저 Id 스프링과 통일
  final String email;
  final String name;
  final String? profileImage;

  ClubMemberProfile({
    required this.clubMemberId,
    required this.isClubAdmin,
    required this.memberId,
    required this.email,
    required this.name,
    this.profileImage
  }); // profileImage
}

class Participant {
  final int participantId;
  final String statusType;
  final TeamConfig teamType;
  final int groupType;
  final ClubMemberProfile clubMember; // member 속성

  Participant({
    required this.participantId,
    required this.statusType,
    required this.teamType,
    required this.groupType,
    required this.clubMember,
  });
}

class DraftParticipantInput {
  final int memberId;
  final TeamConfig teamType;
  final int groupType;

  DraftParticipantInput({
    required this.memberId,
    required this.teamType,
    required this.groupType,
  });
}
