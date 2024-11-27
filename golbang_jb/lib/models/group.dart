import 'member.dart';
// Group 객체를 정의
class Group {
  final int id;
  final String name;
  final String description;
  final String? image;
  final List<Member> members;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.members,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? 'assets/images/golbang_group_default.png',
      members: (json['members'] as List<dynamic>)
          .map((member) => Member.fromJson(member))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // 관리자의 이름을 반환하는 메서드
  String getAdminName() {
    try {
      final admin = members.firstWhere((member) => member.role == 'admin');
      return admin.name;
    } catch (e) {
      return '관리자 없음'; // 관리자 없을 경우
    }
  }
}
