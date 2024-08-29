import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golbang/pages/logins/hi_screen.dart';
import 'package:golbang/pages/signup/signup.dart';
import 'package:golbang/pages/signup/signup_complete.dart';
<<<<<<< HEAD
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:golbang/provider/user_token_provider.dart';
import 'package:golbang/pages/home/home_page.dart';


Future<void> main() async {
  await dotenv.load(fileName: 'assets/config/.env');
  initializeDateFormatting().then((_) => runApp(const MyApp()));
=======
import 'package:golbang/pages/home/home_page.dart';
import 'package:golbang/pages/game/score_card_page.dart';
import 'package:golbang/provider/user_token_provider.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'assets/config/.env');
  // 날짜 형식화를 초기화한 후 앱을 시작합니다.
  initializeDateFormatting().then((_) {
    runApp(
      ProviderScope(
        child: const MyApp(),
      ),
    );
  });
>>>>>>> 5f854be (feat&bug: 모임 생성 페이지 api 연동(post 미동작))
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const HiScreen(),
      routes: {
        '/signup': (context) => SignUpPage(),
        '/signupComplete': (context) => const SignupComplete(),
        // 추가적인 라우트를 여기에 추가할 수 있습니다.
      },
    );
  }
}
