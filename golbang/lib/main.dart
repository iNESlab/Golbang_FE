import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/logins/hi_screen.dart';
import 'screens/logins/signup_step1.dart';
import 'screens/logins/signup_complete.dart';
import 'screens/main_screen.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
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
        '/signupStep1': (context) => const SignUpStep1(),
        '/signupComplete': (context) => const SignupComplete(),
        '/main': (context) => const MainScreen(), // 메인 네비게이션 페이지 경로 추가
      },
    );
  }
}
