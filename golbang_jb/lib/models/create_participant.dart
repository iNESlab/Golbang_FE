import 'package:golbang/models/enum/event.dart';
import 'package:golbang/models/participant.dart';

class CreateParticipant {
  final int memberId;
  final String name;
  final String  profileImage;
  TeamConfig teamType;
  int groupType;

  CreateParticipant({
    required this.memberId,
    required this.name,
    required this.profileImage,
    required this.teamType,
    required this.groupType,
  });

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'team_type': teamType.value,
      'group_type': groupType,
    };
  }

  factory CreateParticipant.fromJson(Map<String, dynamic> json) {
    return CreateParticipant(
      memberId: json['member_id'],
      name: json['name'],
      profileImage: json['profile_image'] ?? '',
      teamType: TeamConfig.values.firstWhere((e) => e.value == json['team_type']),
      groupType: json['group_type'],
    );
  }

  factory CreateParticipant.fromParticipant(Participant participant) {
    return CreateParticipant(
      memberId: participant.member!.memberId,
      name: participant.member!.name,
      profileImage: participant.member!.profileImage,
      teamType: TeamConfig.values.firstWhere(
            (e) => e.value == participant.teamType,
      ),
      groupType: participant.groupType,
    );
  }

// 리스트 변환 메서드
  static List<CreateParticipant> fromParticipants(List<Participant> participants) {
    return participants
        .map((p) => CreateParticipant.fromParticipant(p))
        .toList();
  }
}