// models/club_member.dart
// 모임멤버

import 'package:golbang/models/user.dart';

class ClubMember {

  final User user;
  final String role;
  final int totalPoints;
  final String totalRank;
  final String totalHandicapRank;
  final int totalAvgScore;
  final int totalHandicapAvgScore;


  ClubMember({
    required this.user,
    required this.role,
    required this.totalPoints,
    required this.totalRank,
    required this.totalHandicapRank,
    required this.totalAvgScore,
    required this.totalHandicapAvgScore,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      user: User.fromJson(json['user']),
      role: json['role'],
      totalPoints: json['totalPoints'],
      totalRank: json['totalRank'],
      totalHandicapRank: json['totalHandicapRank'],
      totalAvgScore: json['totalAvgScore'],
      totalHandicapAvgScore: json['totalHandicapAvgScore'],
    );
  }
}
