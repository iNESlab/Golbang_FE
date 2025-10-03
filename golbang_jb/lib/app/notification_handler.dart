import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/app/fcm_service.dart';
import 'package:golbang/app/local_notification_service.dart';
import 'package:golbang/provider/screen_riverpod.dart';
import 'package:golbang/provider/user/user_service_provider.dart';
import '../main.dart'; // navigatorKey 사용

class NotificationHandler extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationHandler({super.key, required this.child});

  // 전역 핸들러 참조
  static void Function(Map<String, dynamic>)? globalHandler;

  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<NotificationHandler> {
  @override
  void initState() {
    super.initState();

    // 전역 핸들러 설정
    NotificationHandler.globalHandler = _handleNotificationClick;

    // FCM 및 로컬 알림 초기화
    FCMService.setup(_handleNotificationClick);
    LocalNotificationService.initialize(onNotificationClick: _handleNotificationClick);
  }

  void _handleNotificationClick(Map<String, dynamic> data) async {
    log("알림 클릭 데이터: $data");

    final userService = ref.read(userServiceProvider);
    final isLoggedIn = await userService.isLoggedIn();

    final context = navigatorKey.currentContext;
    if (context == null) {
      log('❗ navigatorKey.currentContext is null');
      return;
    }

    final eventId = int.tryParse(data['event_id']?.toString() ?? '');
    final clubId = int.tryParse(data['club_id']?.toString() ?? '');
    final chatRoomType = data['chat_room_type']?.toString();
    final messageType = data['type']?.toString();
    final notificationType = data['notification_type']?.toString();

    log('🔍 알림 분석: eventId=$eventId, clubId=$clubId, chatRoomType=$chatRoomType, messageType=$messageType, notificationType=$notificationType');

    if (isLoggedIn && mounted) {
      // 클럽 초대 알림인 경우
      if (notificationType == 'club_invitation' && clubId != null) {
        log('✅ 클럽 초대 알림 - 커뮤니티 메인으로 이동: /app/clubs/$clubId');
        context.go('/app/clubs/$clubId');
      }
      // 클럽 신청 알림인 경우 (관리자에게) - 멤버 관리 페이지의 초대신청 대기 탭으로 직접 이동
      else if (notificationType == 'club_application' && clubId != null) {
        log('✅ 클럽 신청 알림 - 멤버 관리 페이지의 초대신청 대기 탭으로 이동: /app/clubs/$clubId/setting/members');
        context.go('/app/clubs/$clubId/setting/members', extra: {
          'isAdmin': true,
          'initialTabIndex': 1, // 🔧 추가: 초대신청 대기 탭 (인덱스 1)
        });
      }
      // 채팅 메시지 알림인 경우 채팅방으로 직접 이동
      else if (messageType == 'chat_message') {
        if (chatRoomType == 'CLUB' && clubId != null) {
          log('✅ 클럽 채팅방으로 이동: /app/clubs/$clubId/chat');
          context.go('/app/clubs/$clubId/chat');
        } else if (chatRoomType == 'EVENT' && eventId != null) {
          log('✅ 이벤트 채팅방으로 이동: /app/events/$eventId/chat');
          context.go('/app/events/$eventId/chat');
        } else {
          log('❌ 채팅방 정보 부족 - 홈으로 이동');
          context.go('/app/home');
        }
      } else if (eventId != null) {
        log('✅ 이벤트 상세로 이동: /app/events/$eventId');
        context.go('/app/events/$eventId');
      } else if (clubId != null) {
        log('✅ 클럽 상세로 이동: /app/clubs/$clubId');
        context.go('/app/clubs/$clubId');
      } else {
        log('❌ 알 수 없는 알림 - 홈으로 이동');
        context.go('/app/home');
      }
    } else {
      log('❌ 로그인되지 않음 - 로그인 페이지로 이동');
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSizeInitializer(child: widget.child);
  }
}

class AppSizeInitializer extends ConsumerWidget {
  final Widget child;

  const AppSizeInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenSizeProvider.notifier).init(context);
    });

    return child;
  }
}
