import 'dart:developer';

import '../core/network/PrivateClient.dart';
import '../repoisitory/secure_storage.dart';

class NotificationService {
  final SecureStorage storage;
  final privateClient = PrivateClient();
  NotificationService(this.storage);

  // API 테스트 성공
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      const url = '/api/v1/notifications/';

      // API 요청
      final response = await privateClient.dio.get(url);

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

  // API 테스트 성공
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final url = '/api/v1/notifications/$notificationId/';

      // API 요청
      final response = await privateClient.dio.delete(url);

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
