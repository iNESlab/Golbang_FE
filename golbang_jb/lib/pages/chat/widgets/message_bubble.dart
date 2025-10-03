import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:golbang/models/chat_room.dart';
import '../club_chat_page.dart'; // 임시 import - 나중에 제거
import 'image_message.dart';
import 'blocked_message_placeholder.dart';

/// 메시지 버블 위젯
/// 채팅 메시지를 표시하는 독립적인 위젯입니다.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;
  final bool isBlocked;
  final bool isShowingBlocked;
  final double screenWidth;
  final double fontSizeMedium;
  final double fontSizeSmall;
  final bool isUploading;
  final Function(ChatMessage)? onToggleBlockedMessage;
  final Function(ChatMessage)? onShowUnblockDialog;
  final Function(String, String, {bool isUrl})? onImagePreview;
  final Function(ChatMessage)? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    this.isBlocked = false,
    this.isShowingBlocked = false,
    required this.screenWidth,
    required this.fontSizeMedium,
    required this.fontSizeSmall,
    required this.isUploading,
    this.onToggleBlockedMessage,
    this.onShowUnblockDialog,
    this.onImagePreview,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // 🔧 추가: 차단된 메시지 처리
    if (isBlocked && !isShowingBlocked) {
      return _buildBlockedMessagePlaceholder();
    }

    // 🔧 추가: 메시지 타입별 스타일 결정
    bool isAdmin = message.messageType == 'ADMIN';
    bool isAnnouncement = message.messageType == 'ANNOUNCEMENT';
    bool isSystem = message.messageType == 'SYSTEM';

    // 🔧 추가: 차단된 메시지가 보이는 상태일 때 특별한 스타일 적용
    bool showBlockedIndicator = isBlocked && isShowingBlocked;

    // 🔧 추가: 관리자 메시지 content 파싱
    String displayContent = message.content;

    if (isAdmin && message.content.startsWith('{') && message.content.endsWith('}')) {
      try {
        final jsonContent = jsonDecode(message.content);
        if (jsonContent is Map && jsonContent.containsKey('content')) {
          displayContent = jsonContent['content'].toString();
          log('🔍 메시지 빌드에서 관리자 메시지 파싱: $displayContent');
        }
      } catch (e) {
        log('⚠️ 메시지 빌드에서 JSON 파싱 실패: $e');
      }
    }

    // 채팅 박스는 이제 텍스트 길이에 따라 자연스럽게 크기 조절됨

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage && (!isBlocked || isShowingBlocked)) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAdmin
                  ? Colors.orange.shade300
                  : isAnnouncement
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
              // 🔧 수정: 프로필 이미지가 있으면 표시, 없으면 이름 첫 글자
              backgroundImage: message.senderProfileImage != null && message.senderProfileImage!.isNotEmpty
                  ? NetworkImage(message.senderProfileImage!)
                  : null,
              child: message.senderProfileImage == null || message.senderProfileImage!.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty ? message.senderName[0] : '?',
                      style: TextStyle(fontSize: fontSizeSmall),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // 🔧 수정: 메시지 내용에 맞게 너비가 자동 조정되도록 수정
          Flexible(
            child: Align(
              alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
              child: IntrinsicWidth(
                child: GestureDetector(
                  onLongPress: () {
                    onLongPress?.call(message);
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.7,
                      minWidth: 60.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: showBlockedIndicator
                            ? Colors.red.shade50
                            : isSystem
                                ? Colors.orange.shade100
                                : isAdmin
                                    ? Colors.orange.shade100
                                    : isAnnouncement
                                        ? Colors.blue.shade100
                                        : isMyMessage
                                            ? Colors.green
                                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                        border: showBlockedIndicator
                            ? Border.all(color: Colors.red.shade300, width: 2)
                            : isAdmin
                                ? Border.all(color: Colors.orange, width: 2)
                                : isAnnouncement
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : message.isPinned
                                        ? Border.all(color: Colors.amber, width: 2)
                                        : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔧 추가: 차단된 메시지 표시
                          if (showBlockedIndicator)
                            Container(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 12, color: Colors.red.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    '차단된 사용자의 메시지',
                                    style: TextStyle(
                                      fontSize: fontSizeSmall - 2,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      onToggleBlockedMessage?.call(message);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '숨기기',
                                        style: TextStyle(
                                          fontSize: fontSizeSmall - 3,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // 🔧 추가: 발신자 정보 (관리자/공지 표시) - 차단된 사용자는 숨김 (보기 모드에서는 표시)
                          if (!isMyMessage && !isSystem && (!isBlocked || isShowingBlocked))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  if (isAdmin)
                                    Icon(Icons.admin_panel_settings, size: 16, color: Colors.orange.shade800),
                                  if (isAnnouncement)
                                    Icon(Icons.announcement, size: 16, color: Colors.blue.shade800),
                                  if (isAdmin || isAnnouncement) const SizedBox(width: 4),
                                  Text(
                                    message.senderName,
                                    style: TextStyle(
                                      fontSize: fontSizeSmall,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin
                                          ? Colors.orange.shade800
                                          : isAnnouncement
                                              ? Colors.blue.shade800
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 🔧 수정: 메시지 내용 (텍스트 또는 이미지)
                          Row(
                            children: [
                              Expanded(
                                child: isBlocked && !isShowingBlocked
                                    ? GestureDetector(
                                        onTap: () => onToggleBlockedMessage?.call(message),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade400, width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.shade200,
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.block,
                                                size: 18,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '차단된 사용자의 메시지입니다',
                                                  style: TextStyle(
                                                    fontSize: fontSizeSmall,
                                                    color: Colors.grey.shade600,
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.blue.shade200),
                                                ),
                                                child: Text(
                                                  '탭하여 보기',
                                                  style: TextStyle(
                                                    fontSize: fontSizeSmall - 2,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              : message.messageType == 'IMAGE'
                                  ? _buildImageMessage() // TODO: ImageMessage 위젯으로 교체
                                  : (message.messageType == null || message.messageType == 'TEXT' || message.messageType!.isEmpty)
                                      ? Text(
                                          displayContent,
                                          style: TextStyle(
                                            fontSize: fontSizeMedium,
                                            color: isSystem
                                                ? Colors.orange.shade800
                                                : isAdmin
                                                    ? Colors.orange.shade800
                                                    : isAnnouncement
                                                        ? Colors.blue.shade800
                                                        : isMyMessage
                                                            ? Colors.white
                                                            : Colors.black87,
                                          ),
                                          softWrap: true,
                                        )
                                      : Container(), // 기본 위젯 (알 수 없는 타입의 경우)
                        ),
                          if (message.isPinned) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                          ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          // 🔧 추가: 시간과 읽음 표시
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: isSystem
                                      ? Colors.orange.shade600
                                      : isAdmin
                                          ? Colors.orange.shade600
                                          : isAnnouncement
                                              ? Colors.blue.shade600
                                              : isMyMessage
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                ),
                              ),

                              // 🔧 추가: 읽은 사람 수 표시
                              // TODO: 읽음 수 표시 로직 추가
                            ],
                          ),

                          // 🔧 추가: 반응 표시
                          // TODO: 반응 표시 로직 추가
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  /// 차단된 메시지 플레이스홀더 빌더
  Widget _buildBlockedMessagePlaceholder() {
    return BlockedMessagePlaceholder(
      message: message,
      fontSizeSmall: fontSizeSmall,
      fontSizeMedium: fontSizeMedium,
      onToggleBlockedMessage: onToggleBlockedMessage,
    );
  }

  /// 이미지 메시지 빌더
  Widget _buildImageMessage() {
    return ImageMessage(
      message: message,
      isUploading: isUploading,
      screenWidth: screenWidth,
      fontSizeMedium: fontSizeMedium,
      onImagePreview: onImagePreview,
    );
  }

  /// 시간 포맷팅
  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

    if (messageDate == today) {
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '어제 ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${localTime.month}/${localTime.day} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    }
  }
}


