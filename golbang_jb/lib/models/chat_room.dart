class ChatRoom {
  final String chatRoomId;
  final int eventId;
  final int clubId;
  final String chatRoomName;
  final String chatRoomType; // 'EVENT' 또는 'CLUB'
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final int participantCount;
  final List<String> participantIds;
  final bool isActive;
  final int unreadCount; // 🔧 추가: 읽지 않은 메시지 개수

  ChatRoom({
    required this.chatRoomId,
    required this.eventId,
    required this.clubId,
    required this.chatRoomName,
    required this.chatRoomType,
    required this.createdAt,
    this.lastMessageAt,
    required this.participantCount,
    required this.participantIds,
    required this.isActive,
    this.unreadCount = 0, // 🔧 추가: 기본값 0
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatRoomId: json['chatRoomId'] ?? '',
      eventId: json['eventId'] ?? '',
      clubId: json['clubId'] ?? '',
      chatRoomName: json['chatRoomName'] ?? '',
      chatRoomType: json['chatRoomType'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : null,
      participantCount: json['participantCount'] ?? 0,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      isActive: json['isActive'] ?? true,
      unreadCount: json['unreadCount'] ?? 0, // 🔧 추가: 읽지 않은 메시지 개수 파싱
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'eventId': eventId,
      'clubId': clubId,
      'chatRoomName': chatRoomName,
      'chatRoomType': chatRoomType,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'participantCount': participantCount,
      'participantIds': participantIds,
      'isActive': isActive,
      'unreadCount': unreadCount, // 🔧 추가: 읽지 않은 메시지 개수 포함
    };
  }
}

class ChatMessage {
  final String messageId;
  final String chatRoomId;
  final String senderId;
  final String? senderUniqueId; // 🔧 추가: 에코 메시지 방지용 고유 ID
  final String senderName;
  final String? senderProfileImage;
  final String messageType; // 'TEXT', 'IMAGE', 'SYSTEM'
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isPinned; // 🔧 추가: 메시지 고정 여부

  ChatMessage({
    required this.messageId,
    required this.chatRoomId,
    required this.senderId,
    this.senderUniqueId, // 🔧 추가
    required this.senderName,
    this.senderProfileImage,
    required this.messageType,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.isPinned = false, // 🔧 추가: 기본값 false
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderUniqueId: json['sender_unique_id']?.toString(), // 🔧 추가: 고유 ID 파싱
      senderName: json['senderName'] ?? '',
      senderProfileImage: json['senderProfileImage'],
      messageType: json['messageType'] ?? 'TEXT',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      isPinned: json['is_pinned'] ?? false, // 🔧 추가: 고정 여부 파싱
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'sender_unique_id': senderUniqueId, // 🔧 추가: 고유 ID 포함
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'messageType': messageType,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'is_pinned': isPinned, // 🔧 추가: 고정 여부 포함
    };
  }
}
