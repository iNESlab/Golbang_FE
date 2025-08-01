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
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _plugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
              summaryText: '알림 도착',
            ),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
