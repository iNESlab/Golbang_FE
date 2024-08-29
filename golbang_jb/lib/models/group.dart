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

  // JSON 데이터를 Group 객체로 변환하는 함수
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0, // 기본값 설정
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? 'assets/images/apple.png',
      members: (json['members'] as List<dynamic>)
          .map((member) => Member.fromJson(member))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
