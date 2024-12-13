class ClubProfile{
  final int clubId;
  final String name;
  final String image;

  ClubProfile({
    required this.clubId,
    required this.name,
    required this.image,
  });

  factory ClubProfile.fromJson(Map<String, dynamic> json) {
    int groupId = json['id'] ?? 0;
    String defaultImage = 'assets/images/golbang_group_${groupId % 7}.png';
    return ClubProfile(
        clubId: json['id'],
        name: json['name'],
        image: defaultImage
    );
  }
}