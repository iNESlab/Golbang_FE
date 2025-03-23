class Member {
  final int memberId;
  final String name;
  final String role;
  final String profileImage; // profileImage
  final String? description;
  final int accountId;

  Member({
    required this.memberId,
    required this.name,
    required this.role,
    required this.profileImage,
    this.description,
    required this.accountId,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      memberId: json['member_id'] ?? 0, // 'id'가 null인 경우 기본값으로 0 설정
      name: json['user']['name'] ?? '',
      role: json['role'] ?? '',
      profileImage: json['user']['profile_image'] ?? '', // profile_image 추가
      description: json['description'],
      accountId: json['user']['id']
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
}
