import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ErrorHandler {
  /// DioException을 파싱하여 사용자에게 적절한 에러 메시지를 표시
  static void handleDioException(BuildContext context, DioException e) {
    String message = '알 수 없는 오류가 발생했습니다.';
    Color backgroundColor = Colors.red;
    Duration duration = const Duration(seconds: 3);

    if (e.response != null) {
      // 서버에서 응답을 받은 경우
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      developer.log('🔍 에러 응답: $responseData');

      if (statusCode == 400) {
        // 400 Bad Request - 폼 검증 오류
        if (responseData is Map<String, dynamic>) {
          final errors = responseData['errors'];
          final message = responseData['message'];

          if (errors != null) {
            // 특정 필드 에러 처리
            if (errors['email'] != null) {
              final emailError = errors['email'][0];
              if (emailError.contains('이미 존재합니다')) {
                _showSnackBar(
                  context,
                  '이미 가입된 이메일입니다.\n로그인을 사용해주세요.',
                  Colors.orange,
                  const Duration(seconds: 4),
                );
                return;
              } else if (emailError.contains('유효한 이메일 주소')) {
                _showSnackBar(
                  context,
                  '올바른 이메일 형식을 입력해주세요.',
                  Colors.orange,
                  duration,
                );
                return;
              }
            }

            if (errors['user_id'] != null) {
              final userIdError = errors['user_id'][0];
              if (userIdError.contains('이미 존재합니다')) {
                _showSnackBar(
                  context,
                  '이미 사용 중인 아이디입니다.\n다른 아이디를 입력해주세요.',
                  Colors.orange,
                  duration,
                );
                return;
              } else if (userIdError.contains('영문자와 숫자')) {
                _showSnackBar(
                  context,
                  '아이디는 영문자와 숫자만 사용할 수 있습니다.',
                  Colors.orange,
                  duration,
                );
                return;
              }
            }

            if (errors['password1'] != null) {
              final passwordError = errors['password1'][0];
              if (passwordError.contains('너무 짧습니다')) {
                _showSnackBar(
                  context,
                  '비밀번호는 8자 이상 입력해주세요.',
                  Colors.orange,
                  duration,
                );
                return;
              } else if (passwordError.contains('너무 단순합니다')) {
                _showSnackBar(
                  context,
                  '비밀번호가 너무 단순합니다.\n숫자와 특수문자를 포함해주세요.',
                  Colors.orange,
                  duration,
                );
                return;
              }
            }

            if (errors['password2'] != null) {
              _showSnackBar(
                context,
                '비밀번호가 일치하지 않습니다.',
                Colors.orange,
                duration,
              );
              return;
            }

            // 기타 필드 에러
            final firstError = errors.values.first[0];
            _showSnackBar(context, firstError, Colors.orange, duration);
            return;
          }

          // 일반 메시지가 있는 경우
          if (message != null) {
            _showSnackBar(context, message, Colors.orange, duration);
            return;
          }
        }
      } else if (statusCode == 409) {
        // 409 Conflict - 중복 데이터
        _showSnackBar(
          context,
          '이미 가입된 정보입니다.\n다른 정보로 시도해주세요.',
          Colors.orange,
          duration,
        );
        return;
      } else if (statusCode == 500) {
        // 500 Internal Server Error
        _showSnackBar(
          context,
          '서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
          Colors.red,
          duration,
        );
        return;
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout ||
               e.type == DioExceptionType.sendTimeout) {
      // 네트워크 타임아웃
      _showSnackBar(
        context,
        '네트워크 연결이 불안정합니다.\n잠시 후 다시 시도해주세요.',
        Colors.orange,
        duration,
      );
      return;
    } else if (e.type == DioExceptionType.connectionError) {
      // 네트워크 연결 오류
      _showSnackBar(
        context,
        '인터넷 연결을 확인해주세요.',
        Colors.red,
        duration,
      );
      return;
    }

    // 기본 에러 메시지
    _showSnackBar(context, message, backgroundColor, duration);
  }

  /// SnackBar 표시 헬퍼 메서드
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    Duration duration,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 에러 메시지만 추출 (토스트 없이)
  static String extractErrorMessage(DioException e) {
    if (e.response != null) {
      final responseData = e.response!.data;
      
      if (responseData is Map<String, dynamic>) {
        final errors = responseData['errors'];
        final message = responseData['message'];

        if (errors != null) {
          // 특정 필드 에러 처리
          if (errors['email'] != null) {
            final emailError = errors['email'][0];
            if (emailError.contains('이미 존재합니다')) {
              return '이미 가입된 이메일입니다.';
            }
          }

          if (errors['user_id'] != null) {
            final userIdError = errors['user_id'][0];
            if (userIdError.contains('이미 존재합니다')) {
              return '이미 사용 중인 아이디입니다.';
            }
          }

          // 첫 번째 에러 메시지 반환
          return errors.values.first[0];
        }

        if (message != null) {
          return message;
        }
      }
    }

    return '알 수 없는 오류가 발생했습니다.';
  }
}
