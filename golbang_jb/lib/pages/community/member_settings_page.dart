import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/community/member_list_page.dart';
import '../../services/club_service.dart';
import '../../repoisitory/secure_storage.dart';
import 'package:get/get.dart';

class MemberSettingsPage extends ConsumerWidget {
  final int clubId;

  const MemberSettingsPage({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // storage를 가져옴
    final storage = ref.read(secureStorageProvider);
    final clubService = ClubService(storage);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '모임 설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SettingsButton(
              text: '멤버 조회',
              onPressed: () {
                print('멤버 조회 클릭');
                // 멤버 조회 페이지 연결
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberListPage(clubId: clubId),
                  ),
                );
              },
            ),
            SettingsButton(
              text: '모임 나가기',
              textColor: Colors.red,
              onPressed: () {
                _showLeaveConfirmationDialog(context, clubService);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 모임 나가기 확인 다이얼로그
  void _showLeaveConfirmationDialog(BuildContext context, ClubService clubService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('모임 나가기'),
          content: const Text('정말로 모임에서 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                try {
                  await clubService.leaveClub(clubId); // 모임 나가기 API 호출
                  Get.offAllNamed('/home', arguments: {'initialIndex': 2});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임에서 나왔습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임 나가기에 실패했습니다. 다시 시도해주세요.')),
                  );
                }
              },
              child: const Text(
                '나가기',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          ),
          onPressed: onPressed,
          child: Align(
            alignment: Alignment.centerLeft,
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
