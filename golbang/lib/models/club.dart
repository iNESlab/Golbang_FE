import 'member.dart';
// Group 객체를 정의
// TODO: Club으로 바꿔야하는데 사용되는 곳이 너무 많음
class Club {
  final int id;
  final String name;
  final String image;
  String? description;
  final List<Member> members;
  final DateTime createdAt;
  final bool isAdmin;

  Club({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    required this.members,
    required this.createdAt,
    required this.isAdmin, // 필수 필드로 설정
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    int groupId = json['id'] ?? 0;
    String defaultImage = 'assets/images/golbang_group_${groupId % 15}.webp';
    return Club(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? defaultImage,
      description: json['description'] ?? '',
      members: (json['members'] as List<dynamic>)
          .map((member) => Member.fromJson(member))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      isAdmin: json['is_admin'] ?? false, // isAdmin 필드를 JSON에서 가져옴
    );
  }

  Club copyWith({
    int? id,
    String? name,
    String? image,
    bool? isAdmin,
    List<Member>? members,
    DateTime? createdAt,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isAdmin: isAdmin ?? this.isAdmin,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 관리자의 이름을 반환하는 메서드
  List<String> getAdminNames() {
    return members
        .where((member) => member.role == 'admin')
        .map((admin) => admin.name)
        .toList();
  }
}
