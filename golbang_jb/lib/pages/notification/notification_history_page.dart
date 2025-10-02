import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;

import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../../global/PrivateClient.dart';

class NotificationHistoryPage extends ConsumerStatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  NotificationHistoryPageState createState() => NotificationHistoryPageState();
}

class NotificationHistoryPageState extends ConsumerState<NotificationHistoryPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final storage = ref.read(secureStorageProvider);
    final notificationService = NotificationService(storage);

    try {
      final data = await notificationService.fetchNotifications();
      setState(() {
        notifications = data.map((notification) {
          // 임시적으로 eventId나 groupId를 추가
          return {
            ...notification,
            'eventId': notification['event_id'], // 임시 eventId
            'groupId': notification['club_id'], // 임시 groupId
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(int index) async {
    final storage = ref.read(secureStorageProvider);
    final notificationService = NotificationService(storage);

    final notificationId = notifications[index]['notification_id'];

    final success = await notificationService.deleteNotification(notificationId);
    if (success) {
      setState(() {
        notifications.removeAt(index); // 성공 시 UI에서 제거
      });
    } else {
      // 실패 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 삭제에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  void _navigateToDetailPage(Map<String, dynamic> notification) async {
    final eventId = notification['eventId'];
    final clubId = notification['groupId']; //TODO: clubId로 수정해야함
    final notificationType = notification['notification_type']?.toString();
    log('clubId: $clubId, notificationType: $notificationType');

    // 로그인 상태 확인
    final dioClient = PrivateClient();
    final isLoggedIn = !(await dioClient.isAccessTokenExpired());

    if (isLoggedIn && mounted) {
      // 클럽 초대 알림인 경우
      if (notificationType == 'club_invitation' && clubId != null) {
        log('✅ 클럽 초대 알림 - 커뮤니티 메인으로 이동: /app/clubs/$clubId');
        context.go('/app/clubs/$clubId', extra: {'from': 'history'});
      }
      // 클럽 신청 알림인 경우 (관리자에게) - 멤버 관리 페이지의 초대신청 대기 탭으로 직접 이동
      else if (notificationType == 'club_application' && clubId != null) {
        log('✅ 클럽 신청 알림 - 멤버 관리 페이지의 초대신청 대기 탭으로 이동: /app/clubs/$clubId/setting/members');
        context.go('/app/clubs/$clubId/setting/members', extra: {
          'isAdmin': true,
          'initialTabIndex': 1, // 🔧 추가: 초대신청 대기 탭 (인덱스 1)
          'from': 'history',
        });
      }
      // 채팅 메시지 알림인 경우 채팅방으로 직접 이동
      else if (notificationType == 'chat_message') {
        final chatRoomType = notification['chat_room_type']?.toString();
        if (chatRoomType == 'CLUB' && clubId != null) {
          log('✅ 클럽 채팅방으로 이동: /app/clubs/$clubId/chat');
          context.go('/app/clubs/$clubId/chat', extra: {'from': 'history'});
        } else if (chatRoomType == 'EVENT' && eventId != null) {
          log('✅ 이벤트 채팅방으로 이동: /app/events/$eventId/chat');
          context.go('/app/events/$eventId/chat', extra: {'from': 'history'});
        } else {
          log('❌ 채팅방 정보 부족 - 홈으로 이동');
          context.go('/app/home');
        }
      } else if (eventId != null) {
        log('✅ 이벤트 상세로 이동: /app/events/$eventId');
        context.go('/app/events/$eventId', extra: {'from': 'history'});
      } else if (clubId != null) {
        log('✅ 클럽 상세로 이동: /app/clubs/$clubId');
        context.go('/app/clubs/$clubId', extra: {'from': 'history'});
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Image.asset(
          'assets/images/text-logo-green.webp', // 텍스트 로고 이미지 경로
          height: 50, // 이미지 높이 조정
          fit: BoxFit.contain, // 이미지 비율 유지
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              '알림을 불러오는 중입니다...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 50, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '알림이 없습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         const  Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '알림',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '스와이프하여 삭제할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final createdAt =
                DateTime.parse(notification['timestamp']); // timestamp 변환
                final locale = ui.window.locale.toString(); // 예: "ko_KR"
                final relativeTime =
                timeago.format(createdAt, locale: locale.substring(0, 2)); // 상대적 시간 계산
                return Dismissible(
                  key: Key(notification['notification_id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteNotification(index); // API 호출 및 UI 업데이트
                  },
                  child: ListTile(
                    title: Text(
                      notification['title'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
                      maxLines: 1, // 한 줄로 제한
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['body'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2, // 두 줄로 제한
                        ),
                        const SizedBox(height: 4),
                        Text(
                          relativeTime, // "몇 분 전" 표시
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: notification['read']
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle, color: Colors.grey),
                    onTap: () {
                      _navigateToDetailPage(notification); // 알림 클릭 시 상세 페이지로 이동
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
