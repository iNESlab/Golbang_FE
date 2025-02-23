class Member {
  final int memberId;
  final String name;
  final String role;
  final String? profileImage; // profileImage
  final String? description;
  final int id;

  Member({
    required this.memberId,
    required this.name,
    required this.role,
    this.profileImage,
    this.description,
    required this.id,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      memberId: json['member_id'] ?? 0, // 'id'가 null인 경우 기본값으로 0 설정
      name: json['user']['name'] ?? '',
      role: json['role'] ?? '',
      profileImage: json['user']['profile_image'] ?? '', // profile_image 추가
      description: json['description'],
      id: json['user']['id']
    );
  }

  Map<String, dynamic> toJson() {
    return {
        'memberId': memberId,
        'id': id,
        'name': name,
        'role': role,
        // 'profile_image': profileImage,
        'description': description,
    };
  }
}
