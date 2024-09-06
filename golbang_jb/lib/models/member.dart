class Member {
  final int id;
  final String name;
  final String role;
  final String? profileImage; // profileImage
  final String? description;

  Member({
    required this.id,
    required this.name,
    required this.role,
    this.profileImage,
    this.description,
  });

  factory Member.fromJson(Map<String, dynamic> json) {

    print(json);
    return Member(
      id: json['member_id'] ?? 0, // 'id'가 null인 경우 기본값으로 0 설정
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      profileImage: json['profile_image'], // profile_image 추가
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
        'id': id,
        'name': name,
        'role': role,
        'profile_image': profileImage,
        'description': description,
    };
  }
}
