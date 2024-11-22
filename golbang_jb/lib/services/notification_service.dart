import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../repoisitory/secure_storage.dart';

class NotificationService {
  final SecureStorage storage;

  NotificationService(this.storage);

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/notifications/');
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
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        print("알림 히스토리 조회 성공: ${jsonData['data']}");
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        print("알림 조회 실패: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
    }
  }
}
