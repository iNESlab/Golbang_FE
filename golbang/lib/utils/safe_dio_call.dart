import 'package:dio/dio.dart';

Future<T?> safeDioCall<T>(
    Future<T> Function() requestFn, {
      String Function(dynamic error)? errorHandler,
    }) async {
  try {
    return await requestFn();
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      throw Exception('인터넷 연결을 확인해주세요.');
    } else if (e.response != null) {
      final response = e.response!;
      final errorMsg = response.data?['message'] ??
          response.data?['error'] ??
          response.statusMessage ??
          '알 수 없는 서버 오류입니다.';
      throw '에러 코드: ${response.statusCode}\n메시지: $errorMsg';
    } else {
      throw 'Dio 오류: ${e.message}';
    }
  } catch (e) {
    final msg = errorHandler?.call(e) ?? '예기치 못한 오류: $e';
    throw Exception(msg);
  }
}
