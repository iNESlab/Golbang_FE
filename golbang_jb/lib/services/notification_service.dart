import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../repoisitory/secure_storage.dart';

class NotificationService {
  final SecureStorage storage;
  final dioClient = DioClient();
  NotificationService(this.storage);

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final url = '${dotenv.env['API_HOST']}/api/v1/notifications/';

      // API 요청
      final response = await dioClient.dio.get(url);

      if (response.statusCode == 200) {
        final jsonData = response.data;
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        log("알림 조회 실패: ${response.statusCode} - ${response.data}");
        return [];
      }
    } catch (e) {
      log("Error fetching notifications: $e");
      return [];
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final url = '${dotenv.env['API_HOST']}/api/v1/notifications/$notificationId/';

      // API 요청
      final response = await dioClient.dio.delete(url);

      if (response.statusCode == 204) {
        return true;
      } else {
        log("알림 삭제 실패: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      log("Error deleting notification: $e");
      return false;
    }
  }
}
