import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../repoisitory/secure_storage.dart';
import '../models/event.dart';

class EventService {
  final SecureStorage storage;

  EventService(this.storage);

  Future<List<Event>> getEventsForMonth({String? date, String? statusType}) async {
    try {
      // API URL 설정
      //final url = Uri.parse('${dotenv.env['API_HOST']}/events/?date=${date ?? DateTime.now().toIso8601String()}&status_type=');
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/events/');

      // 액세스 토큰 가져오기
      final accessToken = await storage.readAccessToken();

      // API 요청
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes))['data'] as List;
        print("이벤트 목록 조회 성공: ${jsonData.length}개");
        // JSON 데이터를 Event 객체 리스트로 변환
        print(jsonData);


        return jsonData.map((json) => Event.fromJson(json)).toList();
      } else {
        print('이벤트 목록 조회 실패: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error occurred while fetching events: $e');
      return [];
    }
  }
}
