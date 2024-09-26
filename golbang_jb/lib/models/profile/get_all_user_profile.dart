// 전체 사용자 목록을 처리하는 모델 클래스
class GetAllUserProfile {
  final int id;
  final String userId;
  final String profileImage;
  final String name;

  GetAllUserProfile({
    required this.id,
    required this.userId,
    required this.profileImage,
    required this.name,
  });

  // JSON 데이터를 Dart 객체로 변환하는 팩토리 생성자
  factory GetAllUserProfile.fromJson(Map<String, dynamic> json) {
    return GetAllUserProfile(
      id: json['id'],
      userId: json['user_id'],
      profileImage: json['profile_image'] ?? '', // null일 경우 빈 문자열로 처리
      name: json['name'],
    );
  }
}
