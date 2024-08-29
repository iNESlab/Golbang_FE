class UserProfile {
  final int userId;
  final String name;
  final String profileImage;

  UserProfile({
    required this.userId,
    required this.name,
    required this.profileImage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'],
      name: json['name'],
      profileImage: json['profile_image'] ?? 'assets/images/dragon.jpeg'
    );
  }

  // 특정 필드만 추출하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profileImage': profileImage,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
