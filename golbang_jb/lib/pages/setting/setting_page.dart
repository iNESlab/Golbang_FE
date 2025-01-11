import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:golbang/pages/common/privacy_policy_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/auth_service.dart';
import 'feedback_page.dart';
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
        title: const Text('설정',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionHeader(title: '앱 설정'),
          SettingsTile(
            title: '알림 설정',
            onTap: () async {
              final result = await openAppSettings();
              if (!result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('설정 앱을 열 수 없습니다.')),
                );              }
            },
          ),
          const Divider(),
          const SectionHeader(title: '고객지원'),
          SettingsTile(
            title: '개인정보처리방침',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          SettingsTile(
            title: '피드백 보내기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
          ),
          const SettingsTile(
            title: '앱정보',
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          const Divider(),
          SettingsTile(
            title: '로그아웃',
            textColor: Colors.red,
            onTap: () async {
              await _logout(context, authService, storage);
            },
          ),
          SettingsTile(
            title: '회원탈퇴',
            textColor: Colors.red,
            onTap: () async {
              await _deleteAccount(context, userService);
            },
          ),
        ],
      ),
    );
  }

  // 로그아웃 처리
  Future<void> _logout(BuildContext context, AuthService authService, SecureStorage storage) async {
    try {
      final response = await authService.logout(); // 로그아웃 API 호출
      if (response.statusCode == 202) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성공적으로 로그아웃 하였습니다.')),
        );

        Get.offAllNamed('/'); // 모든 이전 페이지 스택 제거 후 로그인 페이지로 이동
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: ${response.data}')),
        );
      }
    } catch (e) {
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
          log('회원탈퇴 성공');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원탈퇴 하였습니다.')),
          );
          Get.offAllNamed('/'); // 모든 이전 페이지 스택 제거 후 로그인 페이지로 이동
        } else {
          final Map<String, dynamic> responseBody = response.data;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'])),
          );
        }
      } catch (e) {
        log('[ERR] 회원탈퇴 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color textColor;

  const SettingsTile({
    required this.title,
    this.onTap,
    this.trailing,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: textColor),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
