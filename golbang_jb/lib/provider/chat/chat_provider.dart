import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../global/PrivateClient.dart';

// 채팅방 상태를 관리하는 provider
class ChatRoomNotifier extends StateNotifier<AsyncValue<ChatRoom?>> {
  final ChatService _chatService;

  ChatRoomNotifier(this._chatService) : super(const AsyncValue.loading());

  // 이벤트 채팅방 생성 또는 조회
  Future<void> getOrCreateEventChatRoom(int eventId, int clubId) async {
    state = const AsyncValue.loading();
    try {
      final chatRoom = await _chatService.getOrCreateEventChatRoom(eventId, clubId);
      state = AsyncValue.data(chatRoom);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // 클럽 채팅방 조회
  Future<void> getClubChatRoom(int clubId) async {
    state = const AsyncValue.loading();
    try {
      final chatRoom = await _chatService.getClubChatRoom(clubId);
      state = AsyncValue.data(chatRoom);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // 채팅방 상태 초기화
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// 채팅방 provider
final chatRoomProvider = StateNotifierProvider<ChatRoomNotifier, AsyncValue<ChatRoom?>>((ref) {
  final chatService = ChatService(PrivateClient());
  return ChatRoomNotifier(chatService);
});

// 채팅 메시지 상태를 관리하는 provider
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _chatRoomId;

  ChatMessagesNotifier(this._chatService, this._chatRoomId) : super(const AsyncValue.loading());

  // 메시지 목록 조회
  Future<void> loadMessages({int limit = 50, int offset = 0}) async {
    state = const AsyncValue.loading();
    try {
      final messages = await _chatService.getChatMessages(_chatRoomId, limit: limit, offset: offset);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // 새 메시지 추가
  void addMessage(ChatMessage message) {
    state.whenData((messages) {
      final newMessages = List<ChatMessage>.from(messages)..add(message);
      state = AsyncValue.data(newMessages);
    });
  }

  // 메시지 전송
  Future<bool> sendMessage(String content, {String messageType = 'TEXT'}) async {
    try {
      final success = await _chatService.sendMessage(_chatRoomId, content, messageType: messageType);
      if (success) {
        // 성공 시 로컬에 메시지 추가
        final newMessage = ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatRoomId: _chatRoomId,
          senderId: 'current_user', // 실제 사용자 ID로 변경 필요
          senderName: '나', // 실제 사용자 이름으로 변경 필요
          messageType: messageType,
          content: content,
          timestamp: DateTime.now(),
          isRead: false,
        );
        addMessage(newMessage);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // 시스템 메시지 전송
  Future<bool> sendSystemMessage(String content) async {
    return await sendMessage(content, messageType: 'SYSTEM');
  }

  // 메시지 상태 초기화
  void reset() {
    state = const AsyncValue.data([]);
  }
}

// 채팅 메시지 provider
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, chatRoomId) {
  final chatService = ChatService(PrivateClient());
  return ChatMessagesNotifier(chatService, chatRoomId);
});

// 채팅방 참가자 상태를 관리하는 provider
class ChatParticipantsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final ChatService _chatService;
  final String _chatRoomId;

  ChatParticipantsNotifier(this._chatService, this._chatRoomId) : super(const AsyncValue.loading());

  // 참가자 목록 조회
  Future<void> loadParticipants() async {
    state = const AsyncValue.loading();
    try {
      final participants = await _chatService.getChatRoomParticipants(_chatRoomId);
      state = AsyncValue.data(participants);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // 참가자 상태 초기화
  void reset() {
    state = const AsyncValue.data([]);
  }
}

// 채팅방 참가자 provider
final chatParticipantsProvider = StateNotifierProvider.family<ChatParticipantsNotifier, AsyncValue<List<String>>, String>((ref, chatRoomId) {
  final chatService = ChatService(PrivateClient());
  return ChatParticipantsNotifier(chatService, chatRoomId);
});
