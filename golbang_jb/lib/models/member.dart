class Member {
  final int id;
  final int groupId;
  final int userId;
  final String role;

  Member({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      groupId: json['groupId'],
      userId: json['userId'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'role': role,
    };
  }
}
