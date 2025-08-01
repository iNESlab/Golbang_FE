import 'dart:developer';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:golbang/app/local_notification_service.dart';

class FCMService {
  /// FCM 세팅 및 메시지 리스너 등록
  static void setup(Function(Map<String, dynamic>) onNotificationClick) async {
    // FCM 토큰 확인
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      log('FCM Token: $token');
      // TODO: 서버로 토큰 전송
    }

    // Foreground 수신 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground message received: ${message.notification}, ${message.data}');
      LocalNotificationService.show(message); // 알림 표시
    });

    // 알림 클릭 처리 (앱이 백그라운드 상태였다가 열림)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('onMessageOpenedApp: ${message.data}');
      onNotificationClick(message.data); // 전달받은 콜백 실행
    });
  }
}
