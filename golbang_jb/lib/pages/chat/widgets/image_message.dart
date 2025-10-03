import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:golbang/models/chat_room.dart';

/// 이미지 메시지 위젯
/// 채팅에서 전송된 이미지를 표시하는 독립적인 위젯입니다.
class ImageMessage extends StatelessWidget {
  final ChatMessage message;
  final bool isUploading;
  final double screenWidth;
  final double fontSizeMedium;
  final Function(String, String, {bool isUrl})? onImagePreview;

  const ImageMessage({
    super.key,
    required this.message,
    required this.isUploading,
    required this.screenWidth,
    required this.fontSizeMedium,
    this.onImagePreview,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // WebSocket으로 받은 메시지는 이미 JSON 객체임 (content가 JSON 문자열)
      final imageData = jsonDecode(message.content);
      if (imageData['type'] == 'image') {
        // 업로드 중 상태 우선 처리
        if (isUploading || imageData['status'] == 'uploading') {
          return Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    '이미지 업로드 중...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // S3 URL 방식 우선, fallback으로 Base64 방식 지원
        final imageUrl = imageData['image_url'] as String?;
        final thumbnailUrl = imageData['thumbnail_url'] as String?;
        final base64Data = imageData['data'] as String?;
        final filename = imageData['filename'] as String? ?? 'image.jpg';

        log('🖼️ 이미지 메시지 표시: URL=${imageUrl?.substring(0, 50)}..., 썸네일=${thumbnailUrl?.substring(0, 50)}...');

        // 표시할 이미지 URL 결정 (썸네일 우선)
        final displayUrl = thumbnailUrl ?? imageUrl;

        if (displayUrl != null) {
          // S3 URL 방식
          return GestureDetector(
            onTap: () => onImagePreview?.call(displayUrl, filename, isUrl: true),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.6,
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  displayUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
          );
        } else if (base64Data != null) {
          // Base64 fallback 방식 (하위 호환성)
          return GestureDetector(
            onTap: () => onImagePreview?.call(base64Data, filename, isUrl: false),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.6,
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(base64Data),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      log('❌ 이미지 메시지 파싱 실패: $e');
    }

    // 파싱 실패 시 텍스트로 표시
    return Text(
      '이미지 로드 실패',
      style: TextStyle(
        fontSize: fontSizeMedium,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
