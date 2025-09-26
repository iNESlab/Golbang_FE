import 'package:golbang/models/profile/member_profile.dart';

class Member {
  final int memberId;
  final String email;
  final String name;
  final String role;
  final String statusType;
  final String profileImage; // profileImage
  final String? description;
  final int accountId;
  final String userId;

  Member({
    required this.memberId,
    required this.email,
    required this.name,
    required this.role,
    required this.statusType,
    required this.profileImage,
    this.description,
    required this.accountId,
    required this.userId
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      memberId: json['member_id'] ?? 0, // 'id'가 null인 경우 기본값으로 0 설정
        email: json['user']['email'] ?? '',
      name: json['user']['name'] ?? '',
      role: json['role'] ?? '',
      statusType: json['status_type'],
      profileImage: json['user']['profile_image'] ?? '', // profile_image 추가
      description: json['description'],
      accountId: json['user']['id'],
      userId: json['user']['userId'] ?? 'UnknownId',
    );
  }

  Map<String, dynamic> toJson() {
    return {
        'member_id': memberId,
        'id': accountId, //TODO: account_id 수정
        'name': name,
        'role': role,
        // 'profile_image': profileImage,
        'description': description,
    };
  }

  ClubMemberProfile toProfile(){
    return ClubMemberProfile(
        memberId: memberId,
        profileImage: profileImage,
        userId: userId,
        name: name,
        role: role,
        statusType: statusType,
        accountId: accountId
    );
  }
}
