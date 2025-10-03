import 'member.dart';
// Group 객체를 정의
// TODO: Club으로 바꿔야하는데 사용되는 곳이 너무 많음
class Club {
  final int id;
  final String name;
  final String image;
  String? description;
  final List<Member> members;
  final DateTime createdAt;
  final bool isAdmin;
  final int unreadCount; // 🔧 추가: 읽지 않은 메시지 개수

  Club({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    required this.members,
    required this.createdAt,
    required this.isAdmin, // 필수 필드로 설정
    this.unreadCount = 0, // 🔧 추가: 기본값 0
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    int groupId = json['id'] ?? 0;
    String defaultImage = 'assets/images/golbang_group_${groupId % 15}.webp';
    return Club(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? defaultImage,
      description: json['description'] ?? '',
      members: (json['members'] as List<dynamic>)
          .map((member) => Member.fromJson(member))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      isAdmin: json['is_admin'] ?? false, // isAdmin 필드를 JSON에서 가져옴
      unreadCount: json['unread_count'] ?? 0, // 🔧 추가: 읽지 않은 메시지 개수 파싱
    );
  }

  Club copyWith({
    int? id,
    String? name,
    String? image,
    bool? isAdmin,
    List<Member>? members,
    DateTime? createdAt,
    int? unreadCount, // 🔧 추가: unreadCount 파라미터
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isAdmin: isAdmin ?? this.isAdmin,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      unreadCount: unreadCount ?? this.unreadCount, // 🔧 추가: unreadCount 복사
    );
  }

  // 관리자의 이름을 반환하는 메서드
  List<String> getAdminNames() {
    return members
        .where((member) => member.role == 'admin')
        .map((admin) => admin.name)
        .toList();
  }

  // 🔧 추가: 현재 사용자의 클럽 상태를 반환하는 메서드
  String? getCurrentUserStatus(int currentUserId) {
    try {
      final currentUserMember = members.firstWhere(
        (member) => member.accountId == currentUserId,
      );
      return currentUserMember.statusType;
    } catch (e) {
      return null; // 사용자가 멤버가 아닌 경우
    }
  }

  // 🔧 추가: 현재 사용자가 클럽에 속해있는지 확인
  bool isUserMember(int currentUserId) {
    return members.any((member) => member.accountId == currentUserId);
  }

  // 🔧 추가: 가입 신청 대기 중인 멤버가 있는지 확인 (관리자용)
  bool get hasPendingApplications {
    return members.any((member) => member.statusType == 'applied');
  }

  // 🔧 추가: 가입 신청 대기 중인 멤버 수 (관리자용)
  int get pendingApplicationsCount {
    return members.where((member) => member.statusType == 'applied').length;
  }
}
