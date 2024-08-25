class Group {
  final int id;
  final String name;
  final String description;
  final String image;
  final int membersCount;
  final DateTime createdAt;
  final bool isActive;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.membersCount,
    required this.createdAt,
    required this.isActive,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      membersCount: json['membersCount'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'membersCount': membersCount,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
