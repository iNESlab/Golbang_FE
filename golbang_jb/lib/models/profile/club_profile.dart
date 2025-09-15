class ClubProfile{
  final int clubId;
  final String name;
  final String image;
  final bool isAdmin;

  ClubProfile({
    required this.clubId,
    required this.name,
    required this.image,
    this.isAdmin = false, // 기본값 false
  });

  factory ClubProfile.fromJson(Map<String, dynamic> json) {
    int groupId = json['id'] ?? 0;
    String defaultImage = 'assets/images/golbang_group_${groupId % 7}.webp';
    return ClubProfile(
        clubId: json['id'],
        name: json['name'],
        image: json['image']??defaultImage,
        isAdmin: json['is_admin'] ?? false,
    );
  }
}