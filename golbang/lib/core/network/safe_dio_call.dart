import 'package:dio/dio.dart';

// core/network/safe_dio_call.dart
import '../error/app_exception.dart';

Future<T> safeDioCall<T>(
    Future<T> Function() requestFn, {
      String Function(Response<dynamic> res)? serverMessagePicker, // 커스터마이징 가능
    }) async {
  try {
    return await requestFn();
  } on DioException catch (e) {
    // 연결 계열
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      throw const NetworkException('인터넷 연결을 확인해주세요.');
    }

    // 서버 응답 계열
    if (e.response != null) {
      final res = e.response!;
      final msg = serverMessagePicker?.call(res) ??
          (res.data is Map
              ? (res.data['message'] ?? res.data['error'] ?? res.statusMessage)
              : res.statusMessage) ??
          '알 수 없는 서버 오류입니다.';
      throw ServerException(msg.toString(), statusCode: res.statusCode);
    }

    // 그 외
    throw UnknownException('Dio 오류: ${e.message}');
  } catch (e) {
    if (e is AppException) rethrow; // 이미 정제된 예외는 그대로
    throw UnknownException('예기치 못한 오류: $e');
  }
}
