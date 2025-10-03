import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:golbang/app/local_notification_service.dart';
import 'package:golbang/app/current_route_service.dart';

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
      log('🔔 FCM Foreground 메시지 수신!');
      log('📱 알림 제목: ${message.notification?.title}');
      log('📱 알림 내용: ${message.notification?.body}');
      log('📱 데이터: ${message.data}');
      log('📱 메시지 ID: ${message.messageId}');
      log('📱 발송 시간: ${message.sentTime}');
      
      // 🔧 추가: 알림 타입 확인
      final notificationType = message.data['notification_type'];
      final messageType = message.data['type'];
      final msgType = message.data['msgType']; // 🔧 추가: FCM에서 전송하는 메시지 타입
      final chatRoomId = message.data['chat_room_id'];
      final chatRoomType = message.data['chat_room_type'];
      
      log('🔍 알림 타입: $notificationType');
      log('🔍 메시지 타입: $messageType');
      log('🔍 FCM 메시지 타입: $msgType');
      log('🔍 채팅방 ID: $chatRoomId, 타입: $chatRoomType');
      log('🔍 현재 라우트: ${CurrentRouteService.currentRoute}');
      log('🔍 현재 채팅방 ID: ${CurrentRouteService.currentChatRoomId}');
      log('🔍 현재 채팅방 타입: ${CurrentRouteService.currentChatRoomType}');
      
      // 채팅 메시지 알림인 경우에만 채팅방 확인
      if ((notificationType == 'chat_message' || messageType == 'chat_message') && chatRoomId != null && chatRoomType != null) {
        // 현재 해당 채팅방을 보고 있는지 확인
        final isViewing = CurrentRouteService.isViewingChatRoomByType(chatRoomId, chatRoomType);
        log('🔍 현재 채팅방을 보고 있는가? $isViewing');
        log('🔍 비교 대상: chatRoomId=$chatRoomId, chatRoomType=$chatRoomType');
        log('🔍 현재 상태: currentChatRoomId=${CurrentRouteService.currentChatRoomId}, currentChatRoomType=${CurrentRouteService.currentChatRoomType}');
        
        if (isViewing) {
          log('🚫 현재 채팅방을 보고 있음 - 알림 표시 안 함');
          return;
        }
      }
      
      log('✅ 알림 표시 진행');
      LocalNotificationService.show(message); // 알림 표시
    });

    // 알림 클릭 처리 (앱이 백그라운드 상태였다가 열림)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('🔔 FCM 백그라운드 알림 클릭!');
      log('📱 알림 제목: ${message.notification?.title}');
      log('📱 알림 내용: ${message.notification?.body}');
      log('📱 데이터: ${message.data}');
      log('📱 메시지 ID: ${message.messageId}');
      onNotificationClick(message.data); // 전달받은 콜백 실행
    });
  }
}
