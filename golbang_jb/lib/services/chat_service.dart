import 'dart:convert';
import 'dart:developer';
import '../models/chat_room.dart';
import '../global/PrivateClient.dart';

class ChatService {
  final PrivateClient _client;

  ChatService(this._client);

  // 이벤트 채팅방 생성 또는 조회
  Future<ChatRoom?> getOrCreateEventChatRoom(int eventId, int clubId) async {
    try {
      final response = await _client.dio.get('/api/v1/chat/event/${eventId.toString()}');

      if (response.statusCode == 200) {
        return ChatRoom.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // 채팅방이 없으면 생성
        return await _createEventChatRoom(eventId, clubId);
      } else {
        log('Failed to get event chat room: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error getting event chat room: $e');
      return null;
    }
  }

  // 이벤트 채팅방 생성
  Future<ChatRoom?> _createEventChatRoom(int eventId, int clubId) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/chat/event',
        data: {
          'event_id': eventId,
          'club_id': clubId,
        },
      );

      if (response.statusCode == 201) {
        return ChatRoom.fromJson(response.data);
      } else {
        log('Failed to create event chat room: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error creating event chat room: $e');
      return null;
    }
  }

  // 클럽 채팅방 조회
  Future<ChatRoom?> getClubChatRoom(int clubId) async {
    try {
      final response = await _client.dio.get('/api/v1/chat/club/${clubId.toString()}');

      if (response.statusCode == 200) {
        return ChatRoom.fromJson(response.data);
      } else {
        log('Failed to get club chat room: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error getting club chat room: $e');
      return null;
    }
  }

  // 채팅방 메시지 조회
  Future<List<ChatMessage>> getChatMessages(String chatRoomId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _client.dio.get(
        '/api/v1/chat/${chatRoomId.toString()}/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messages = response.data['messages'] ?? [];
        return messages.map((msg) => ChatMessage.fromJson(msg)).toList();
      } else {
        log('Failed to get chat messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error getting chat messages: $e');
      return [];
    }
  }

  // 메시지 전송
  Future<bool> sendMessage(String chatRoomId, String content, {String messageType = 'TEXT'}) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/chat/${chatRoomId.toString()}/messages',
        data: {
          'content': content,
          'message_type': messageType,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      log('Error sending message: $e');
      return false;
    }
  }

  // 🔧 추가: 채팅방 읽지 않은 메시지 개수 조회
  Future<int> getUnreadCount(String chatRoomId) async {
    try {
      final response = await _client.dio.get(
        '/api/v1/chat/unread-count/',
        queryParameters: {
          'chat_room_id': chatRoomId,
        },
      );

      if (response.statusCode == 200) {
        return response.data['unread_count'] ?? 0;
      } else {
        log('Failed to get unread count: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      log('Error getting unread count: $e');
      return 0;
    }
  }

  // 🔧 추가: 모든 채팅방 읽지 않은 메시지 개수 조회
  Future<Map<String, int>> getAllUnreadCounts() async {
    try {
      final response = await _client.dio.get('/api/v1/chat/unread-counts/');

      if (response.statusCode == 200) {
        return Map<String, int>.from(response.data['unread_counts'] ?? {});
      } else {
        log('Failed to get all unread counts: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      log('Error getting all unread counts: $e');
      return {};
    }
  }

  // 🔧 추가: 메시지 읽음 표시
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/chat/mark-read/',
        data: {
          'message_id': messageId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error marking message as read: $e');
      return false;
    }
  }

  // 🔧 추가: 채팅방의 모든 메시지 읽음 표시
  Future<bool> markAllMessagesAsRead(String chatRoomId) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/chat/mark-all-read/',
        data: {
          'chat_room_id': chatRoomId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error marking all messages as read: $e');
      return false;
    }
  }

  // 채팅방 참가자 목록 조회
  Future<List<String>> getChatRoomParticipants(String chatRoomId) async {
    try {
      final response = await _client.dio.get('/api/v1/chat/${chatRoomId.toString()}/participants');

      if (response.statusCode == 200) {
        return List<String>.from(response.data['participantIds'] ?? []);
      } else {
        log('Failed to get participants: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error getting participants: $e');
      return [];
    }
  }

  // 🔧 추가: 채팅방 알림 설정 조회
  Future<bool> getChatRoomNotificationStatus(String chatRoomId) async {
    try {
      final response = await _client.dio.get(
        '/api/v1/chat/room-info/',
        queryParameters: {
          'chat_room_id': chatRoomId,
        },
      );

      if (response.statusCode == 200) {
        return response.data['chat_room']['is_notification_enabled'] ?? true;
      } else {
        log('Failed to get notification status: ${response.statusCode}');
        return true; // 기본값
      }
    } catch (e) {
      log('Error getting notification status: $e');
      return true; // 기본값
    }
  }

  // 🔧 추가: 채팅방 알림 설정 토글
  Future<bool> toggleChatRoomNotification(String chatRoomId) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/chat/toggle-notification/',
        data: {
          'chat_room_id': chatRoomId,
        },
      );

      if (response.statusCode == 200) {
        log('Notification toggled: ${response.data['message']}');
        return response.data['setting']['is_enabled'] ?? true;
      } else {
        log('Failed to toggle notification: ${response.statusCode}');
        return true; // 기본값
      }
    } catch (e) {
      log('Error toggling notification: $e');
      return true; // 기본값
    }
  }
}