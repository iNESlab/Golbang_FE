class User {
  final int userId;
  final String username;
  final String role;
  final String fullname;
  final String email;
  final String loginType;
  final String provider;
  final String password;
  final String mobile;
  final String address;
  final DateTime dateOfBirth;
  final String handicap;
  final String studentId;
  final String profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime recentConnectionTime;
  final DateTime releaseAt;

  User({
    required this.userId,
    required this.username,
    required this.role,
    required this.fullname,
    required this.email,
    required this.loginType,
    required this.provider,
    required this.password,
    required this.mobile,
    required this.address,
    required this.dateOfBirth,
    required this.handicap,
    required this.studentId,
    required this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    required this.recentConnectionTime,
    required this.releaseAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      username: json['username'],
      role: json['role'],
      fullname: json['fullname'],
      email: json['email'],
      loginType: json['loginType'],
      provider: json['provider'],
      password: json['password'],
      mobile: json['mobile'],
      address: json['address'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      handicap: json['handicap'],
      studentId: json['studentId'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      recentConnectionTime: DateTime.parse(json['recentConnectionTime']),
      releaseAt: DateTime.parse(json['releaseAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'role': role,
      'fullname': fullname,
      'email': email,
      'loginType': loginType,
      'provider': provider,
      'password': password,
      'mobile': mobile,
      'address': address,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'handicap': handicap,
      'studentId': studentId,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'recentConnectionTime': recentConnectionTime.toIso8601String(),
      'releaseAt': releaseAt.toIso8601String(),
    };
  }
}
