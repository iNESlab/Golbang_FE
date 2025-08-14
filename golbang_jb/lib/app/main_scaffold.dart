import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/reponsive_utils.dart';


class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _getIndex(location);

    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;
    double appBarSize = ResponsiveUtils.getAppBarHeight(screenWidth, orientation);
    double appBarIconSize = ResponsiveUtils.getAppBarIconSize(screenWidth, orientation);

    return Scaffold(

      appBar: AppBar(
        title: Image.asset(
          'assets/images/text-logo-green.webp',
          height: appBarSize, // 이미지 높이 조정
          fit: BoxFit.contain, // 이미지 비율 유지,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => context.push('/app/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => context.push('/app/setting'),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/app/home');
              break;
            case 1:
              context.go('/app/events');
              break;
            case 2:
              context.go('/app/clubs');
              break;
            case 3:
              context.go('/app/user');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '모임'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/events')) return 1;
    if (location.startsWith('/clubs')) return 2;
    if (location.startsWith('/user')) return 3;
    return 0;
  }
}
