import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/app/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:golbang/app/app_initializer.dart';
import 'package:golbang/app/notification_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
