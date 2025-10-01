import 'package:flutter/material.dart';
import 'package:golbang/models/chat_room.dart';
import 'package:golbang/services/chat/block_service.dart';
import 'message_bubble.dart';

/// 메시지 리스트 위젯
/// 채팅 메시지들을 리스트 형태로 표시하는 독립적인 위젯입니다.
class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String currentUserId;
  final BlockService blockService;
  final Set<String> uploadingMessages;
  final ScrollController scrollController;
  final double screenWidth;
  final double fontSizeMedium;
  final double fontSizeSmall;
  final Function(ChatMessage)? onToggleBlockedMessage;
  final Function(ChatMessage)? onShowUnblockDialog;
  final Function(String, String, {bool isUrl})? onImagePreview;
  final Function(ChatMessage)? onLongPress;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.blockService,
    required this.uploadingMessages,
    required this.scrollController,
    required this.screenWidth,
    required this.fontSizeMedium,
    required this.fontSizeSmall,
    this.onToggleBlockedMessage,
    this.onShowUnblockDialog,
    this.onImagePreview,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // 🔧 추가: 모든 메시지 표시 (차단된 메시지는 다르게 렌더링)
    final visibleMessages = messages;

    return ListView.builder(
      key: ValueKey(visibleMessages.length), // 🔧 추가: 보이는 메시지 개수 변경 시에만 리빌드
      controller: scrollController,
      reverse: true, // 🔧 추가: 맨 아래에서 시작
      padding: const EdgeInsets.all(16),
      itemCount: visibleMessages.length,
      itemBuilder: (context, index) {
        final message = visibleMessages[visibleMessages.length - 1 - index];
        // 🔧 수정: 실제 사용자 ID로 비교 (문자열 비교)
        // log('🎨 UI 메시지 비교: senderId="${message.senderId}" (${message.senderId.runtimeType}) vs currentUserId="$currentUserId" (${currentUserId.runtimeType})');
        // 🔧 추가: 관리자 메시지는 항상 왼쪽에 표시 (내가 보낸 것이라도)
        final isMyMessage = message.messageType == 'ADMIN' ? false : message.senderId.toString() == currentUserId;
        // log('🎨 UI 비교 결과: $isMyMessage (관리자 메시지: ${message.messageType == 'ADMIN'})');

        final isBlocked = blockService.isUserBlocked(message.senderId);
        final isShowingBlocked = blockService.showBlockedMessages.contains(message.messageId);

        // 🔧 추가: 차단된 메시지 디버그 로그
        if (isBlocked) {
          // log('🚫 UI 렌더링: 차단된 메시지 - ${message.senderName} (${message.senderId}), 보기모드: $isShowingBlocked');
        }

        // 🔧 수정: 메시지별 고유 Key 추가로 애니메이션 최적화
        return KeyedSubtree(
          key: ValueKey('${message.messageId}_${message.timestamp.millisecondsSinceEpoch}'),
          child: MessageBubble(
            message: message,
            isMyMessage: isMyMessage,
            isBlocked: isBlocked,
            isShowingBlocked: isShowingBlocked,
            screenWidth: screenWidth,
            fontSizeMedium: fontSizeMedium,
            fontSizeSmall: fontSizeSmall,
            isUploading: uploadingMessages.contains(message.messageId),
            onToggleBlockedMessage: onToggleBlockedMessage,
            onShowUnblockDialog: onShowUnblockDialog,
            onImagePreview: onImagePreview,
            onLongPress: onLongPress,
          ),
        );
      },
    );
  }
}
