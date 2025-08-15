import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;

/// Firebase 백그라운드 메시지 핸들러
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Background message received: ${message.messageId}");
}

/// 앱 전반 초기화
Future<void> initializeApp() async {
  // 환경변수 로드
  await dotenv.load(fileName: 'assets/config/.env');

  // Firebase 초기화
  await Firebase.initializeApp();

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 알림 권한 요청
  await _requestNotificationPermission();

  // 타임존 초기화 (시간대 관련 알림 등을 위한 설정)
  tz.initializeTimeZones();
}

/// 알림 권한 요청 (Firebase + permission_handler)
Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 상태 확인 로그
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    log('사용자가 알림 권한을 승인했습니다.');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    log('사용자가 임시 알림 권한을 승인했습니다.');
  } else {
    log('알림 권한이 거부되었습니다.');
  }
}
