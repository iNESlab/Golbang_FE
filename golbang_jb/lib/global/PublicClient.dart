import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';

import '../pages/logins/login.dart';

class PublicClient {
  late Dio _dio;

  PublicClient()
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

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 정상 응답 처리
        return handler.next(response);
      },
      onError: (error, handler) async {
        log('publicClient에러: $error');
        return handler.next(error);
      }
    ));
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
