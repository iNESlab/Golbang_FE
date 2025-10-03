import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:golbang/app/notification_handler.dart';

/// 채팅 알림 서비스
/// 로컬 푸시 알림을 관리합니다.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInForeground = true; // 앱이 포그라운드에 있는지 확인

  /// 앱 포그라운드 상태 설정
  void setForegroundState(bool isForeground) {
    _isInForeground = isForeground;
    log('📱 NotificationService: 앱 포그라운드 상태 변경: $isForeground');
  }

  /// 로컬 알림 초기화
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 탭 시 처리
        log('📱 NotificationService: 알림 탭됨: ${response.payload}');
        
        // payload가 있으면 알림 핸들러로 전달
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            // JSON 파싱하여 알림 핸들러로 전달
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            log('📱 NotificationService: 파싱된 데이터: $data');
            
            // 알림 핸들러 호출 (전역에서 접근 가능하도록)
            if (NotificationHandler.globalHandler != null) {
              NotificationHandler.globalHandler!(data);
            }
          } catch (e) {
            log('❌ NotificationService: payload 파싱 실패: $e');
          }
        }
      },
    );

    // Android 채널 설정
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages', // 채널 ID
      '채팅 메시지', // 채널 이름
      description: '새로운 채팅 메시지 알림',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    log('✅ NotificationService: 로컬 알림 초기화 완료');
  }

  /// 채팅 메시지 알림 표시
  /// [message]가 도착하면 알림을 표시합니다.
  Future<void> showChatNotification({
    required String messageId,
    required String senderName,
    required String content,
    required String senderId,
    required String currentUserId,
    required String messageType,
    required String chatRoomId,
    required String clubId,
    required String chatRoomType,
  }) async {
    // 자신이 보낸 메시지는 알림하지 않음
    if (senderId == currentUserId) return;

    // 앱이 포그라운드에 있을 때만 알림 표시
    if (!_isInForeground) return;

    // 시스템/관리자 메시지는 알림하지 않음
    if (messageType == 'SYSTEM' || messageType == 'ADMIN') return;

    final notificationId = messageId.hashCode; // 메시지 ID를 해시로 사용

    String displayContent = content;
    String title = '${senderName}님이 메시지를 보냈습니다';

    // 이미지 메시지인 경우
    if (messageType == 'IMAGE') {
      displayContent = '사진을 보냈습니다';
    }

    // 긴 메시지는 축약
    if (displayContent.length > 50) {
      displayContent = '${displayContent.substring(0, 50)}...';
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      '채팅 메시지',
      channelDescription: '새로운 채팅 메시지 알림',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // payload 데이터 구성
    final payloadData = {
      'sender_name': senderName,
      'chat_room_id': chatRoomId,
      'club_id': clubId,
      'sender_id': senderId,
      'type': 'chat_message',
      'chat_room_type': chatRoomType,
    };

    await _notificationsPlugin.show(
      notificationId,
      title,
      displayContent,
      details,
      payload: jsonEncode(payloadData),
    );

    log('📱 NotificationService: 채팅 알림 표시: $title - $displayContent');
  }

  /// 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
