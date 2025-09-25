import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/chat_room.dart';
import '../repoisitory/secure_storage.dart';

class ChatService {
  final SecureStorage _storage;
  static const String baseUrl = 'https://your-api-url.com/api'; // 실제 API URL로 변경 필요

  ChatService(this._storage);

  // 이벤트 채팅방 생성 또는 조회
  Future<ChatRoom?> getOrCreateEventChatRoom(int eventId, int clubId) async {
    try {
      final token = await _storage.readAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/chat/event/${eventId.toString()}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatRoom.fromJson(data);
      } else if (response.statusCode == 404) {
        // 채팅방이 없으면 생성
        return await _createEventChatRoom(eventId, clubId);
      } else {
        log('Failed to get chat room: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error getting chat room: $e');
      return null;
    }
  }

  // 이벤트 채팅방 생성
  Future<ChatRoom?> _createEventChatRoom(int eventId, int clubId) async {
    try {
      final token = await _storage.readAccessToken();

      final response = await http.post(
        Uri.parse('$baseUrl/chat/event'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'eventId': eventId.toString(),
          'clubId': clubId.toString(),
          'chatRoomType': 'EVENT',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatRoom.fromJson(data);
      } else {
        log('Failed to create chat room: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error creating chat room: $e');
      return null;
    }
  }

  // 클럽 채팅방 조회
  Future<ChatRoom?> getClubChatRoom(int clubId) async {
    try {
      final token = await _storage.readAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/chat/club/${clubId.toString()}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatRoom.fromJson(data);
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
      final token = await _storage.readAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/chat/${chatRoomId.toString()}/messages?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = data['messages'] as List;
        return messages.map((msg) => ChatMessage.fromJson(msg)).toList();
      } else {
        log('Failed to get messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error getting messages: $e');
      return [];
    }
  }

  // 메시지 전송
  Future<bool> sendMessage(String chatRoomId, String content, {String messageType = 'TEXT'}) async {
    try {
      final token = await _storage.readAccessToken();

      final response = await http.post(
        Uri.parse('$baseUrl/chat/${chatRoomId.toString()}/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'messageType': messageType,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      log('Error sending message: $e');
      return false;
    }
  }

  // 시스템 메시지 전송 (이벤트 시작, 종료 등)
  Future<bool> sendSystemMessage(String chatRoomId, String content) async {
    return await sendMessage(chatRoomId, content, messageType: 'SYSTEM');
  }

  // 채팅방 참가자 목록 조회
  Future<List<String>> getChatRoomParticipants(String chatRoomId) async {
    try {
      final token = await _storage.readAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/chat/${chatRoomId.toString()}/participants'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['participantIds'] ?? []);
      } else {
        log('Failed to get participants: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error getting participants: $e');
      return [];
    }
  }
}
