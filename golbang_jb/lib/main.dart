import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:golbang/pages/group/group_main.dart';
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
import 'package:golbang/provider/user/user_service_provider.dart';
import 'services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:golbang/pages/event/event_detail.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:golbang/models/event.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

// timezone 패키지 추가
import 'package:timezone/data/latest.dart' as tz;

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
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // timezone 데이터 초기화 및 한국 시간 설정
  tz.initializeTimeZones(); // 최신 시간대 데이터 로드

  initializeDateFormatting().then((_) {
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  });
  await Firebase.initializeApp(); // Firebase 초기화
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
          fontFamily: 'KoPubWorld',
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
          GetPage(name: '/', page: () => const TokenCheck()),
          GetPage(name: '/signup', page: () => SignUpPage()),
          GetPage(name: '/signupComplete', page: () => const SignupComplete()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/event', page: () => const EventPage()),
          GetPage(name: '/group', page: () => GroupMainPage()),
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
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    initUniLinks();
    setupFCM();
    _initializeLocalNotifications();
  }

  Future<void> initUniLinks() async {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.host == 'golbang-test' && uri.queryParameters.containsKey('event_id')) {
      final eventId = int.tryParse(uri.queryParameters['event_id']!);

      if (eventId != null) {
        try {
          final storage = ref.read(secureStorageProvider);
          final eventService = EventService(storage);

          // 이벤트 상세 정보를 불러오기
          final event = await eventService.getEventDetails(eventId);

          if (event != null) {
            Get.to(() => EventDetailPage(event: event));
          } else {
            print('이벤트를 찾을 수 없습니다.');
          }
        } catch (e) {
          print('이벤트 데이터를 불러오는 중 오류 발생: $e');
        }
      }
    }
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

    int? eventId;
    int? clubId;

    if (data.containsKey('event_id')) {
      eventId = int.tryParse(data['event_id'].toString());
      print("Event ID: $eventId");
    } else if (data.containsKey('club_id')) {
      clubId = int.tryParse(data['club_id'].toString());
      print("Club ID: $clubId");
    }

    if (isLoggedIn) {
      if (eventId != null) {
        Get.offAll(() => const HomePage(), arguments: {
          'initialIndex': 1,
          'eventId': eventId
        });
      } else if (clubId != null) {
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
            styleInformation: BigTextStyleInformation(
              notification.body ?? '', // 긴 텍스트를 멀티라인으로 표시
              contentTitle: notification.title, // 제목
              summaryText: '알림 요약', // 알림 요약 (옵션)
            ),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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