class User {
  final int userId;
  final String userToken;
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
    required this.userToken,
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
      userToken: json['userToken'],
      username: json['username'],
      role: json['role'],
      fullname: json['fullname'],
      email: json['email'],
      loginType: json['loginType'],
      provider: json['providers'],
      password: json['password'],
      mobile: json['mobile'],
      address: json['address'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']).toLocal(),
      handicap: json['handicap'],
      studentId: json['studentId'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt']).toLocal(),
      recentConnectionTime: DateTime.parse(json['recentConnectionTime']).toLocal(),
      releaseAt: DateTime.parse(json['releaseAt']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userToken': userToken,
      'username': username,
      'role': role,
      'fullname': fullname,
      'email': email,
      'loginType': loginType,
      'providers': provider,
      'password': password,
      'mobile': mobile,
      'address': address,
      'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
      'handicap': handicap,
      'studentId': studentId,
      'profileImage': profileImage,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'recentConnectionTime': recentConnectionTime.toUtc().toIso8601String(),
      'releaseAt': releaseAt.toUtc().toIso8601String(),
    };
  }
  User? getUserByToken(List<User> users, String token) {
    // List에서 특정 token과 일치하는 User를 찾아 반환
    for (var user in users) {
      if (user.userToken == token) {
        return user;
      }
    }
    // 일치하는 User가 없으면 null 반환
    return null;
  }
}
