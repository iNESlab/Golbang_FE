import 'get_all_user_profile.dart';

class ClubMemberProfile {
  final int memberId;
  String profileImage;
  final String userId;
  final String name;
  final String role;
  final String statusType;
  final int accountId;

  ClubMemberProfile({
    required this.memberId,
    required this.profileImage,
    required this.userId,
    required this.name,
    required this.role,
    required this.statusType,
    required this.accountId,
  });

  factory ClubMemberProfile.fromJson(Map<String, dynamic> json) {
    return ClubMemberProfile(
        memberId: json['member_id'],
        profileImage: json['user']['profile_image'] ?? '',
        userId: json['user']['user_id'] ?? 'UnknownID',
        name: json['user']['name'],
        role: json['role'],
        statusType: json['status_type'],
        accountId: json['user']['id']
    );
  }

  GetAllUserProfile toUserProfile(){
    return GetAllUserProfile(
        accountId: accountId,
        profileImage: profileImage,
        name: name
    );
  }

  // ✅ copyWith 메서드 추가
  ClubMemberProfile copyWith({
    int? memberId,
    String? name,
    String? role,
    String? userId,
    String? profileImage,
    int? accountId,
    String? statusType,
  }) {
    return ClubMemberProfile(
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      profileImage: profileImage ?? this.profileImage,
      accountId: accountId ?? this.accountId,
      statusType: statusType ?? this.statusType,
    );
  }

  // 특정 필드만 추출하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'name': name,
      'role': role,
      'id': accountId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubMemberProfile && other.memberId == memberId;
  }

  @override
  int get hashCode => memberId.hashCode;
}
