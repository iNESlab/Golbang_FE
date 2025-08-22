import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/app/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:golbang/app/app_initializer.dart';
import 'package:golbang/app/notification_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>(); // 👈 추가

/// ✅ 다운로더 백그라운드 콜백 (반드시 top-level + entry-point)
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  // 여기서는 print/log 정도만 — UI 접근/플러그인 호출 금지
  // debugPrint('BG DOWNLOAD => id=$id, status=$status, progress=$progress');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 flutter_downloader 초기화 (반드시 가장 먼저, 1회)
  await FlutterDownloader.initialize(
    debug: kDebugMode, // 디버그 모드에서 로그 보려면 true
    // ignoreSsl: false, // (옵션) 필요한 경우만
  );

  // ✅ 백그라운드 콜백 등록 (이게 없으면 iOS에서 크래시)
  FlutterDownloader.registerCallback(downloadCallback);

  await initializeApp(); // ✅ 앱 초기화

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
    return NotificationHandler( // ✅ 알림 핸들러 적용
      child: MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: 'GOLBANG MAIN PAGE',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ko', 'KR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
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
        routerConfig: appRouter, // ✅ GoRouter 주입
      ),
    );
  }
}
