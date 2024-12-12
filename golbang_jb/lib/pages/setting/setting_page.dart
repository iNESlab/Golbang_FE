import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/auth_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    // SecureStorage 및 AuthService 인스턴스 가져오기
    final storage = ref.read(secureStorageProvider);
    final authService = AuthService(storage);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 알림 설정 버튼
            SettingsButton(
              text: '알림 설정',
              onPressed: () async {
                final result = await openAppSettings();
                if (!result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('설정 앱을 열 수 없습니다.')),
                  );
                }
              },
            ),
            // 로그아웃 버튼
            SettingsButton(
              text: '로그아웃',
              textColor: Colors.red,
              onPressed: () async {
                await _logout(context, authService, storage);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 로그아웃 처리
  Future<void> _logout(BuildContext context, AuthService authService, SecureStorage storage) async {
    try {
      final response = await authService.logout(); // 로그아웃 API 호출
      if (response.statusCode == 202) {
        print('로그아웃 성공');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성공적으로 로그아웃 하였습니다.')),
        );

        Get.offAllNamed('/'); // 모든 이전 페이지 스택 제거 후 로그인 페이지로 이동
      } else {
        print('로그아웃 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: ${response.body}')),
        );
      }
    } catch (e) {
      print('[ERR] 로그아웃 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }
}

class SettingsButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final VoidCallback onPressed;

  const SettingsButton({
    required this.text,
    required this.onPressed,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 버튼 간 여백
      child: SizedBox(
        width: double.infinity, // 버튼이 화면 너비를 가득 차지
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200], // 버튼 배경색
            elevation: 0, // 그림자 제거
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // 내부 여백 설정
          ),
          onPressed: onPressed,
          child: Align(
            alignment: Alignment.centerLeft, // 텍스트를 버튼 왼쪽 정렬
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
