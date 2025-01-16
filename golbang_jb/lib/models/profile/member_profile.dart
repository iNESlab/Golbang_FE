class ClubMemberProfile {
  final int memberId;
  String? profileImage;
  final String name;
  final String role;

  ClubMemberProfile({
    required this.memberId,
    String? profileImage,
    required this.name,
    required this.role,
  }) : profileImage = (profileImage == null || profileImage.isEmpty) ? null : profileImage;

  factory ClubMemberProfile.fromJson(Map<String, dynamic> json) {
    return ClubMemberProfile(
        memberId: json['member_id'],
        profileImage: json['profile_image'],
        name: json['name'],
        role: json['role']
    );
  }

  // 특정 필드만 추출하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'name': name,
      'role': role,
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