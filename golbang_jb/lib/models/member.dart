class Member {
  final int id;
  final String name;
  final String email;
  final String role;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    // 'user' 키를 통해 중첩된 JSON 데이터를 파싱
    final userJson = json['user'];
    if (userJson == null) {
      throw FormatException("Invalid data: 'user' cannot be null");
    }

    return Member(
      id: userJson['id'] ?? 0, // 'id'가 null인 경우 기본값으로 0 설정
      name: userJson['name'] ?? '',
      email: userJson['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'name': name,
        'email': email,
      },
      'role': role,
    };
  }
}
