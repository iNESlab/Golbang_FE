// models/club_member.dart
// 모임멤버

import 'package:golbang/models/user.dart';

class ClubMember {
  final User user;
  final String role;

  ClubMember({
    required this.user,
    required this.role,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      user: User.fromJson(json['user']),
      role: json['role'],
    );
  }
}
