import 'dart:convert';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'importance_channel',
    'Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// 초기화 (메인에서 1회만 호출)
  static Future<void> initialize({
    required Function(Map<String, dynamic>) onNotificationClick,
  }) async {
    // Android 채널 생성
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        log("iOS Local Notification: $id, $title, $body, $payload");
      },
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            onNotificationClick(data); // 알림 클릭 콜백 실행
          } catch (e) {
            log("Error parsing notification payload: $e");
          }
        }
      },
    );
  }

  /// Foreground 상태에서 푸시 메시지를 로컬 알림으로 보여줌
  static void show(RemoteMessage message) {
    log('🔔 로컬 알림 표시 시작');
    final notification = message.notification;
    final android = message.notification?.android;

    // 🔧 추가: 사진 메시지 처리
    String? displayBody = notification?.body;
    final messageType = message.data['type'];
    final msgType = message.data['msgType']; // 🔧 수정: FCM에서 전송하는 키 사용
    final senderName = message.data['sender_name'];
    
    // 사진 메시지인 경우 로그 출력
    if (messageType == 'chat_message' && msgType == 'IMAGE') {
      log('📱 사진 메시지 감지됨: $displayBody');
    }

    log('📱 알림 정보: ${notification?.title} - $displayBody');
    log('📱 Android 정보: ${android != null ? "있음" : "없음"}');

    if (notification != null) {
      log('✅ 알림 표시 진행 (Android 정보 무시)');
      _plugin.show(
        notification.hashCode,
        notification.title,
        displayBody ?? notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              displayBody ?? notification.body ?? '',
              contentTitle: notification.title,
              summaryText: '알림 도착',
            ),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } else {
      log('❌ 알림 표시 실패: notification 정보 없음');
      log('📱 notification: ${notification != null ? "있음" : "없음"}');
    }
  }
}
