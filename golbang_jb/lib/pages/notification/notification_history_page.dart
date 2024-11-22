import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알림 히스토리',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text('알림이 없습니다.'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(notification['title']),
            subtitle: Text(notification['body']),
            trailing: notification['read']
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle, color: Colors.grey),
            onTap: () {
              // 알림 클릭 시 동작 추가 가능
              print("알림 클릭: ${notification['notification_id']}");
            },
          );
        },
      ),
    );
  }
}
