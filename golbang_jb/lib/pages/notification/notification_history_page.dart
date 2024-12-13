import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:golbang/pages/event/event_detail.dart';
import 'package:golbang/pages/home/home_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../repoisitory/secure_storage.dart';

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
      print(data);
      setState(() {
        notifications = data.map((notification) {
          // 임시적으로 eventId나 groupId를 추가
          return {
            ...notification,
            'eventId': 36, // 임시 eventId
            'groupId': 5, // 임시 groupId
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching notifications: $e");
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

  void _navigateToDetailPage(Map<String, dynamic> notification) {
    final eventId = notification['eventId'];
    final groupId = notification['groupId'];
    if (eventId != null) {
      Get.offAll(() => const HomePage(), arguments: {
        'initialIndex': 1,
        'eventId': eventId
      });
    } else if (groupId != null) {
      Get.offAll(() => const HomePage(), arguments: {
        'initialIndex': 2,
        'communityId': groupId
      });
    } else {
      // 예외 처리: 이동할 수 없음
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상세 정보를 확인할 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GOLBANG',
          style: TextStyle(color: Colors.green, fontSize: 25),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '알림',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '스와이프하여 삭제할 수 있습니다.',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                final relativeTime =
                timeago.format(createdAt, locale: 'ko'); // 상대적 시간 계산
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
