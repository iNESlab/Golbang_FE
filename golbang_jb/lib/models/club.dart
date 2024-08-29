// models/club.py
// 모임

class Club {
  final int id;
  final String name;
  final String description;
  final String? image;
  final List<ClubMember> members;
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.members,
    required this.createdAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      members: (json['members'] as List)
          .map((member) => ClubMember.fromJson(member))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ClubMember {
  final User user;
  final String role;

  ClubMember({required this.user, required this.role});

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      user: User.fromJson(json['user']),
      role: json['role'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}