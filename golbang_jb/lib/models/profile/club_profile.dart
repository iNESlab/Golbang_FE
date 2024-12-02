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
    return ClubProfile(
        clubId: json['id'],
        name: json['name'],
        image: json['image'] ?? 'assets/images/golbang_group_default.png'
    );
  }
}