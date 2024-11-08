import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/logins/login.dart';
import 'package:golbang/pages/logins/signup_complete.dart';
import 'package:golbang/pages/signup/signup.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'firebase_options.dart';

// 전역으로 채널 선언
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'importance_channel', // 채널 ID
  'Importance Notifications', // 채널 이름
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  await dotenv.load(fileName: 'assets/config/.env');
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 알림 채널 설정
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    setupFCM();
  }

  void setupFCM() async {
    // 알림 권한 요청 및 결과 확인
    PermissionStatus status = await Permission.notification.request();
    print("Notification permission status: $status");

    if (status.isGranted) {
      print("Notification permission granted");
    } else if (status.isDenied) {
      print("Notification permission denied");
    } else if (status.isPermanentlyDenied) {
      print("Notification permission permanently denied");
    }

    // 이후 FCM 토큰 출력 및 알림 리스너 설정
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");

    // 포그라운드 상태에서 알림 수신 리스너 설정
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("포그라운드에서 알림 수신: ${message.notification?.title} - ${message.notification?.body}");
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
              importance: Importance.high,
              icon: '@drawable/logo',
            ),
          ),
        );
      }
    });
  }


  void setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/logo');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const LoginPage(),
      routes: {
        '/signup': (context) => SignUpPage(),
        '/signupComplete': (context) => const SignupComplete(),
      },
    );
  }
}

// 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("백그라운드에서 메시지 수신: ${message.messageId}");
}
