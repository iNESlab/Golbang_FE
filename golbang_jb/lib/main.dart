import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await Firebase.initializeApp(); // Firebase 초기화

  await _requestNotificationPermission();

  // timezone 데이터 초기화 및 한국 시간 설정
  tz.initializeTimeZones(); // 최신 시간대 데이터 로드

  initializeDateFormatting().then((_) {
    runApp(
      const ProviderScope(
        child: MyApp(),
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

        // 로캘 설정(앱의 기본 언어와 지역을 설정)
        locale: const Locale('ko', 'KR'),

        // 지원 로캘
        supportedLocales: const [
          Locale('en', 'US'), // 영어
          Locale('ko', 'KR'), // 한국어
        ],

        // 로컬라이제이션 델리게이트 설정
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,  // Material 위젯 번역 지원
          GlobalWidgetsLocalizations.delegate,  // 기본 Flutter 위젯 번역 지원
          GlobalCupertinoLocalizations.delegate, // iOS 위젯 번역 지원
        ],

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
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initAppLinks();
    setupFCM();
    _initializeLocalNotifications();
  }

  void setupFCM() async {
    await _requestNotificationPermission();

    // FCM 토큰 가져오기
    FirebaseMessaging.instance.getToken().then((String? token) {
      if (token != null) {
        print("FCM Token: $token");
        // TODO: 토큰을 서버로 전송
      }
    });

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

  Future<void> _initAppLinks() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleDeepLink(uri);
      });
    } catch (e) {
      print('Error initializing app links: $e');
    }
  }

  void _navigateToTarget({int? eventId, int? clubId}) async {
    final userService = ref.read(userServiceProvider);
    final isLoggedIn = await userService.isLoggedIn();

    if (isLoggedIn) {
      if (eventId != null) {
        Get.offAll(() => const HomePage(), arguments: {'initialIndex': 1, 'eventId': eventId});
      } else if (clubId != null) {
        Get.offAll(() => const HomePage(), arguments: {'initialIndex': 2, 'communityId': clubId});
      } else {
        Get.offAll(() => const HomePage());
      }
    } else {
      Get.toNamed('/', arguments: {'redirectEventId': eventId, 'redirectClubId': clubId});
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'golbang-test') {
      final eventId = int.tryParse(uri.queryParameters['event_id'] ?? '');
      final clubId = int.tryParse(uri.queryParameters['club_id'] ?? '');
      _navigateToTarget(eventId: eventId, clubId: clubId);
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
    _linkSubscription?.cancel();
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

Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Firebase 권한 요청
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 권한 상태 로그 출력
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('사용자가 알림 권한을 승인했습니다.');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('사용자가 임시 알림 권한을 승인했습니다.');
  } else {
    print('알림 권한이 거부되었습니다.');
  }
}