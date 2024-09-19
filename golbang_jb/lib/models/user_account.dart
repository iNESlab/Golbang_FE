// models/user_account.dart
// 사용자 정보 조회 시 사용되는 모델

class UserAccount {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String address; // Nullable 처리
  final DateTime? dateOfBirth;
  final int handicap;
  final String? studentId; // Nullable 처리
  String? profileImage; // Nullable 처리

  UserAccount({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber, // Nullable
    required this.address, // Nullable
    this.dateOfBirth,
    required this.handicap,
    this.studentId, // Nullable
    this.profileImage, // Nullable
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      address: json['address'] ?? 'Unknown', // Nullable 처리
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      handicap: json['handicap'] ?? 0, // 기본값 처리
      studentId: json['student_id'] as String?, // Nullable 처리
      profileImage: json['profile_image'] as String?, // Nullable 처리
    );
  }
}
