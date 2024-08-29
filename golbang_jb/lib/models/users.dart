// models/users.dart
// 사용자
// 추후 이 코드를 models/user.dart에 덮어씌워야 함

class User {
  final int id;
  final String userId;
  final String email;
  final String name;
  final String phoneNumber;
  final String address;
  final DateTime? dateOfBirth;
  final int handicap;
  final String? studentId;
  final String? profileImage;

  User({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.dateOfBirth,
    required this.handicap,
    this.studentId,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userId: json['user_id'],
      email: json['email'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      handicap: json['handicap'],
      studentId: json['student_id'],
      profileImage: json['profile_image'],
    );
  }
}
