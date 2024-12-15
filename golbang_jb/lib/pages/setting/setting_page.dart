import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

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
    final userService = UserService(storage);

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
                await _logout(context, authService);
              },
            ),
            SettingsButton(
                text: '회원탈퇴',
                textColor: Colors.red,
                onPressed: () async {
                  await _deleteAccount(context, userService);
                },
            ),
          ],
        ),
      ),
    );
  }

  // 로그아웃 처리
  Future<void> _logout(BuildContext context, AuthService authService) async {
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

  Future<void> _deleteAccount(BuildContext context, UserService userService) async {
    // 재확인 다이얼로그 띄우기
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // 둥근 모서리 추가
          backgroundColor: Colors.white, // 배경을 흰색으로 설정
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 다이얼로그 크기를 내용에 맞춤
              children: [
                const Text(
                  '회원탈퇴',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16), // 간격 추가
                const Text(
                  '정말로 회원탈퇴 하시겠습니까?\n\n'
                      '개인정보처리방침에 따라 일부 데이터가 삭제되지 않을 수 있습니다.\n\n'
                      '모임 관리자인 경우, 다른 관리자가 없는 상태에서는 회원탈퇴가 제한됩니다. '
                      '이 경우 먼저 새로운 관리자를 지정해 주세요.',
                  style: TextStyle(fontSize: 14, height: 1.5), // 줄 간격 조정
                  textAlign: TextAlign.left, // 텍스트 정렬
                ),
                const SizedBox(height: 24), // 간격 추가
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // 버튼을 오른쪽 정렬
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false), // 취소
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8), // 버튼 간 간격
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true), // 확인
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // 사용자가 확인을 눌렀을 때만 API 호출
    if (shouldDelete == true) {
      try {
        final response = await userService.deleteAccount(); // 회원탈퇴 API 호출
        if (response.statusCode == 200) {
          print('회원탈퇴 성공');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원탈퇴 하였습니다.')),
          );
          Get.offAllNamed('/'); // 모든 이전 페이지 스택 제거 후 로그인 페이지로 이동
        } else {
          print('회원탈퇴 실패: ${response.body}');
          final Map<String, dynamic> responseBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'])),
          );
        }
      } catch (e) {
        print('[ERR] 회원탈퇴 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
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
