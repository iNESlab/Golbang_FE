import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../global/PrivateClient.dart';

/// 채팅 이미지 처리 서비스
/// 이미지 선택, 업로드, 미리보기 등의 기능을 제공합니다.
class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  /// 이미지 선택
  /// [source]에서 이미지를 선택합니다.
  Future<void> pickImage(
    ImageSource source, {
    required Function(XFile?) onImageSelected,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      onImageSelected(image);
    } catch (e) {
      log('❌ ImageService: 이미지 선택 실패: $e');
      onImageSelected(null);
    }
  }

  /// 서버에 이미지 업로드
  /// [imageFile]을 서버에 업로드하고 결과를 반환합니다.
  Future<Map<String, dynamic>?> uploadImageToServer(XFile imageFile) async {
    try {
      final privateClient = PrivateClient();

      // MultipartFile 생성
      final bytes = await imageFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
        contentType: MediaType.parse(imageFile.mimeType ?? 'image/jpeg'),
      );

      final formData = FormData.fromMap({
        'image': multipartFile,
      });

      final response = await privateClient.dio.post(
        '/api/v1/chat/upload-image/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          log('✅ ImageService: 이미지 업로드 성공: ${data['image_url']}');
          return {
            'image_url': data['image_url'],
            'thumbnail_url': data['thumbnail_url'],
            'filename': data['filename'],
            'size': data['size'],
            'content_type': data['content_type']
          };
        }
      }

      log('❌ ImageService: 이미지 업로드 실패: ${response.statusCode}');
      return null;

    } catch (e) {
      log('❌ ImageService: 이미지 업로드 오류: $e');
      return null;
    }
  }

  /// 이미지 선택 다이얼로그 표시
  /// 카메라 또는 갤러리 선택 다이얼로그를 표시합니다.
  void showImagePickerDialog({
    required BuildContext context,
    required Function(ImageSource) onSourceSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '이미지 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: '갤러리',
                  onTap: () {
                    Navigator.pop(context);
                    onSourceSelected(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 이미지 미리보기 다이얼로그 표시
  /// 선택된 이미지를 미리보기하고 전송할 수 있습니다.
  void showImagePreviewDialog({
    required BuildContext context,
    required XFile imageFile,
    required Function() onSend,
    required Function() onCancel,
    required double screenHeight,
    required double Function() getFontSizeMedium,
    required double Function() getFontSizeSmall,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫기 방지
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          height: screenHeight * 0.8, // 화면 높이의 80%
          child: Column(
            children: [
              // 헤더 (취소 버튼)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black.withOpacity(0.7),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        onCancel();
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    Text(
                      '이미지 미리보기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: getFontSizeMedium(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // 대칭을 위해
                  ],
                ),
              ),

              // 이미지 표시 영역
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.file(
                        File(imageFile.path),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '이미지를 불러올 수 없습니다',
                                  style: TextStyle(
                                    fontSize: getFontSizeMedium(),
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 하단 액션 버튼들
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.9),
                child: Row(
                  children: [
                    // 파일명 표시
                    Expanded(
                      child: Text(
                        imageFile.name.length > 20
                            ? '${imageFile.name.substring(0, 17)}...'
                            : imageFile.name,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: getFontSizeSmall(),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 전송 버튼
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // 미리보기 닫기
                        onSend(); // 실제 전송
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(
                        '전송',
                        style: TextStyle(fontSize: getFontSizeMedium()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이미지 선택 옵션 위젯 빌더
  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
