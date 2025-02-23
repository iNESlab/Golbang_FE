// models/club.py
// 모임


class Club {
  final int id;
  final String name;
  final String description;
  final String image;
  // final List<ClubMember> members;
  //TODO Error: Failed to load clubs: type 'Null' is not a subtype of type 'Map<String, dynamic>'
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    // required this.members,
    required this.createdAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    // var membersFromJson = json['members'] as List;
    // List<ClubMember> memberList = membersFromJson.map((i) => ClubMember.fromJson(i)).toList();
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image']??'assets/images/naver.png',
      // members: memberList,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
