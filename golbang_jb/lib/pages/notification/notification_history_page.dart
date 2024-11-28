import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      setState(() {
        notifications = data;
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
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            '알림을 불러오는 중입니다...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      )
          : notifications.isEmpty
          ? Center( // "알림이 없습니다"를 화면 정중앙에 표시
        child: Column(
          mainAxisSize: MainAxisSize.min, // 필요한 만큼만 크기 차지
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
          : Column( // 알림이 있는 경우 상단에 제목 표시
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '알림',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final createdAt = DateTime.parse(notification['timestamp']); // timestamp 변환
                final relativeTime = timeago.format(createdAt, locale: 'ko'); // 상대적 시간 계산
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['body']),
                        const SizedBox(height: 4),
                        Text(
                          relativeTime, // "몇 분 전" 표시
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: notification['read']
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle, color: Colors.grey),
                    onTap: () {
                      print("알림 클릭: ${notification['notification_id']}");
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
