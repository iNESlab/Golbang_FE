class Member {
  final int id;
  final String name;
  final String role;

  Member({
    required this.id,
    required this.name,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {

    print(json);
    return Member(
      id: json['member_id'] ?? 0, // 'id'가 null인 경우 기본값으로 0 설정
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
        'id': id,
        'name': name,
        'role': role,
    };
  }
}
