// 이벤트 수정 시 사용하는 참여자 객체


import 'package:golbang/models/participant.dart';

import 'member.dart';
import 'profile/member_profile.dart';

class UpdateEventParticipant {
  final int memberId;
  final String name;
  final String profileImage;
  final String role;
  final int participantId;
  final String statusType;
  final String teamType;
  final int? holeNumber;
  final int groupType;
  final int? sumScore;
  final String rank;
  final String handicapRank;
  final int handicapScore;

  UpdateEventParticipant({
    required this.memberId,
    required this.name,
    required this.profileImage,
    required this.role,
    required this.participantId,
    required this.statusType,
    required this.teamType,
    this.holeNumber,
    required this.groupType,
    this.sumScore,
    required this.rank,
    required this.handicapRank,
    required this.handicapScore,
  });

  factory UpdateEventParticipant.fromJson(Map<String, dynamic> json) {
    return UpdateEventParticipant(
      memberId: json['member']['member_id'],
      name: json['member']['name'],
      profileImage: json['member']['profile_image'] ?? '',
      role: json['member']['role'],
      participantId: json['participant_id'],
      statusType: json['status_type'],
      teamType: json['team_type'],
      holeNumber: json['hole_number'],
      groupType: json['group_type'],
      sumScore: json['sum_score'],
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      handicapScore: json['handicap_score'],
    );
  }

  factory UpdateEventParticipant.fromClubMemberProfile(ClubMemberProfile profile) {
    return UpdateEventParticipant(
      memberId: profile.memberId,
      name: profile.name,
      profileImage: profile.profileImage,
      role: profile.role,
      participantId: 0, // 실제 데이터에 맞게 설정 필요
      statusType: 'PENDING', // 적절한 값으로 설정 필요
      teamType: '', // 적절한 값으로 설정 필요
      groupType: 0, // 적절한 값으로 설정 필요
      handicapRank: '',
      rank: '',
      handicapScore: 0,
    );
  }

  // UpdateEventParticipant를 Participant로 변환하는 메서드 추가
  Participant toParticipant() {
    return Participant(
      participantId: participantId,
      statusType: statusType,
      teamType: teamType,
      holeNumber: holeNumber,
      groupType: groupType,
      sumScore: sumScore,
      rank: rank,
      handicapRank: handicapRank,
      handicapScore: handicapScore,
      member: Member(
        memberId: memberId,
        name: name,
        role: role,
        profileImage: profileImage,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'name': name,
      'profile_image': profileImage,
      'role': role,
      'participant_id': participantId,
      'status_type': statusType,
      'team_type': teamType,
      'hole_number': holeNumber,
      'group_type': groupType,
      'sum_score': sumScore,
      'rank': rank,
      'handicap_rank': handicapRank,
      'handicap_score': handicapScore,
    };
  }
}