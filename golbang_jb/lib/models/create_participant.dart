import 'package:golbang/models/enum/event.dart';

class CreateParticipant {
  final int memberId;
  final String name;
  String? profileImage;
  TeamConfig teamType;
  int groupType;

  CreateParticipant({
    required this.memberId,
    required this.name,
    String? profileImage,
    required this.teamType,
    required this.groupType,
  }) : profileImage = (profileImage == null || profileImage.isEmpty) ? null : profileImage;

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
}