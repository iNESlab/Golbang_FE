import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

import '../main.dart';

class PrivateClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  PrivateClient()
      : _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_HOST']!, // 예: https://api.example.com
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )){
    // 로깅 활성화
    _dio.interceptors.add(LogInterceptor(
      request: true, // 요청 로깅
      // requestHeader: true, // 요청 헤더 로깅
      // requestBody: true, // 요청 바디 로깅
      // responseHeader: true, // 응답 헤더 로깅
      responseBody: true, // 응답 바디 로깅
      error: true, // 에러 로깅
    ));

    // 공통 Interceptor 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 기본 Content-Type 설정
        if (!options.headers.containsKey('Content-Type')) {
          options.headers['Content-Type'] = 'application/json';
          // 멀티 파트 요청시 최하단 주석 코드 참고
        }

        // 요청 전에 Access Token을 헤더에 추가
        final accessToken = await _storage.read(key: 'ACCESS_TOKEN');
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 정상 응답 처리
        return handler.next(response);
      },
      onError: (error, handler) async {
        // 401 에러 처리
        if (error.response?.statusCode == 401) {
          final isTokenExpired = await isAccessTokenExpired();
          if (isTokenExpired) {
            log('Access token expired, redirecting to login page.');
            await _logoutAndRedirect();
          } else {
            log('Access token is valid but unauthorized.');
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<int?> getAccountId() async {
    try {
      final accessToken = await _storage.read(key: 'ACCESS_TOKEN');
      if (accessToken == null) return null;

      // JWT payload 디코딩
      final payload = json.decode(
        utf8.decode(
          base64Url.decode(base64Url.normalize(accessToken.split('.')[1])),
        ),
      );

      return payload['user_id']; // ⚠️ 여기 key는 백엔드 JWT payload 구조에 맞게 수정
    } catch (e) {
      log("Error decoding userId from token: $e");
      return null;
    }
  }

  Future<bool> isAccessTokenExpired() async {
    try {
      final accessToken = await _storage.read(key: 'ACCESS_TOKEN');
      if (accessToken == null) return true;

      // 토큰 디코딩
      final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(accessToken.split('.')[1]))));
      final exp = payload['exp']; // 만료 시간
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000; // 현재 시간

      return exp < currentTime; // 만료 시간이 현재 시간보다 이전이면 만료
    } catch (e) {
      log('Error checking token expiration: $e');
      return true; // 에러 발생 시 만료로 간주
    }
  }

  Future<void> _logoutAndRedirect() async {
    // 스토리지에서 토큰 제거
    await _storage.deleteAll();

    // 로그인 페이지로 이동
    // context 없이도 안전하게 사용 가능
    final ctx = navigatorKey.currentState?.context;
    if (ctx != null) {
      ctx.go(
        '/app',
        extra: {'message': '로그인 토큰이 만료되었습니다. 다시 로그인해주세요.'},
      );
    }
  }

  Dio get dio => _dio;
}

// Future<void> uploadFile(String filePath) async {
//   var formData = FormData.fromMap({
//     'file': await MultipartFile.fromFile(filePath, filename: 'upload.jpg'),
//   });
//
//   var response = await dio.post(
//     '/upload',
//     data: formData, // dio에서 json으로 바꿔주므로 jsonEncoder 불필요
//     options: Options(headers: {'Content-Type': 'multipart/form-data'}),
//   );
//
//   log('File upload response: ${response.data}');
// }
