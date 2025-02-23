class ClubMemberProfile {
  final int memberId;
  String profileImage;
  final String name;
  final String role;
  final int id;

  ClubMemberProfile({
    required this.memberId,
    required this.profileImage,
    required this.name,
    required this.role,
    required this.id,
  });

  factory ClubMemberProfile.fromJson(Map<String, dynamic> json) {
    return ClubMemberProfile(
        memberId: json['member_id'],
        profileImage: json['user']['profile_image'] ?? '',
        name: json['user']['name'],
        role: json['role'],
        id: json['user']['id']
    );
  }

  // 특정 필드만 추출하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'name': name,
      'role': role,
      'id': id,
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
