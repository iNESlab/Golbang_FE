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

  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<NotificationHandler> {
  @override
  void initState() {
    super.initState();

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

    if (isLoggedIn) {
      if (eventId != null) {
        context.go('/event', extra: {
          'initialIndex': 1,
          'eventId': eventId,
        });
      } else if (clubId != null) {
        context.go('/club', extra: {
          'initialIndex': 2,
          'communityId': clubId,
        });
      } else {
        context.go('/home');
      }
    } else {
      context.go('/', extra: {
        'redirectEventId': eventId,
        'redirectClubId': clubId,
      });
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
