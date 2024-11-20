import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:golbang/pages/home/home_page.dart';
import 'package:golbang/pages/logins/login.dart';
import 'package:golbang/pages/logins/signup_complete.dart';
import 'package:golbang/pages/signup/signup.dart';
import 'package:golbang/pages/event/event_main.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'repoisitory/secure_storage.dart';
import 'package:golbang/provider/user/user_service_provider.dart';
import 'services/user_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'importance_channel',
  'Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env');
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  initializeDateFormatting().then((_) {
    runApp(
      ProviderScope(
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationHandler(
      child: GetMaterialApp(
        title: 'GOLBANG MAIN PAGE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          appBarTheme: const AppBarTheme(
            color: Colors.white,
            foregroundColor: Colors.black,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
          ),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        initialRoute: '/', // 초기 라우트 설정
        getPages: [
          GetPage(name: '/', page: () => const LoginPage()),
          GetPage(name: '/signup', page: () => SignUpPage()),
          GetPage(name: '/signupComplete', page: () => const SignupComplete()),
          GetPage(name: '/event', page: () => const EventPage()),
        ],
      ),
    );
  }
}

class NotificationHandler extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationHandler({Key? key, required this.child}) : super(key: key);

  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<NotificationHandler> {
  @override
  void initState() {
    super.initState();
    setupFCM();
    _initializeLocalNotifications();
  }


  void setupFCM() async {
    await _requestNotificationPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification}, ${message.data}");
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onMessageOpenedApp 확인: ${message.data}");
      _handleNotificationClick(message.data);
    });
  }

  void _handleNotificationClick(Map<String, dynamic> data) async {
    print("Notification Click Data: $data");
    final userService = ref.read(userServiceProvider);
    final isLoggedIn = await userService.isLoggedIn();
    print("로그인 확인: $isLoggedIn");

    if (isLoggedIn) {
      if (data.containsKey('event_id')) {
        String eventId = data['event_id'];
        print("Event ID: $eventId");
        Get.offAll(() => const HomePage(), arguments: {
          'initialIndex': 1,
          'eventId': eventId
        });
      } else if (data.containsKey('club_id')) {
        String clubId = data['club_id'];
        print("Club ID: $clubId");
        Get.offAll(() => const HomePage(), arguments: {
          'initialIndex': 2,
          'communityId': clubId
        });
      }
    } else {
      print("LoginPage로 이동.");
      Get.toNamed('/'); // 로그인 페이지로 이동
    }
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print("Notification payload: ${response.payload}");
          try {
            final data = response.payload!.isNotEmpty
                ? (jsonDecode(response.payload!) as Map<dynamic, dynamic>)
                .map((key, value) => MapEntry(key.toString(), value))
                : <String, dynamic>{};
            _handleNotificationClick(data);
          } catch (e) {
            print("Error parsing notification payload: $e");
          }
        } else {
          print("Notification payload is null or empty.");
        }
      },
    );
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Firebase 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
}