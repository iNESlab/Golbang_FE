import 'dart:convert';
import 'dart:async';
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
import 'package:golbang/pages/event/event_detail.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:golbang/provider/user/user_service_provider.dart';
import 'package:golbang/models/event.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_links/app_links.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

  // timezone 데이터 초기화
  tz.initializeTimeZones();

  initializeDateFormatting().then((_) {
    runApp(const ProviderScope(child: MyApp()));
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
          GetPage(name: '/', page: () => const LoginPage()),
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

  void setupFCM() async {
    await _requestNotificationPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final eventId = int.tryParse(data['event_id']?.toString() ?? '');
    final clubId = int.tryParse(data['club_id']?.toString() ?? '');
    _navigateToTarget(eventId: eventId, clubId: clubId);
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handleNotificationClick(data);
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
