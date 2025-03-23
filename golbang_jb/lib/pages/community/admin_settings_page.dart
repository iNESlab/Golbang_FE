import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/pages/club/club_edit_page.dart';
import 'package:golbang/pages/community/member_list_page.dart';
import '../../services/club_service.dart';
import '../../repoisitory/secure_storage.dart';
import 'package:get/get.dart';

class AdminSettingsPage extends ConsumerWidget {
  final Group club; // 모임 ID를 받도록 수정

  const AdminSettingsPage({super.key, required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // storage를 Riverpod에서 가져옴
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
        centerTitle: true, // 제목을 중앙으로 정렬
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SettingsButton(
              text: '멤버 조회',
              onPressed: () {
                log('멤버 조회 클릭');
                // 멤버 조회 페이지 연결 (생략)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberListPage(clubId: club.id, isAdmin: true,),
                  ),
                );
              },
            ),
            // TODO: 멤버 관리 페이지 추후 만들어야 함
            // SettingsButton(
            //   text: '멤버 관리',
            //   onPressed: () {
            //     log('멤버 관리 클릭');
            //     // 멤버 관리 페이지 연결 (생략)
            //   },
            // ),
            SettingsButton(
              text: '모임 관리',
              onPressed: () {
                log('모임 관리 클릭');
                // 멤버 조회 페이지 연결 (생략)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClubEditPage(club: club),
                  ),
                );
              },
            ),
            SettingsButton(
              text: '모임 삭제하기',
              textColor: Colors.red,
              onPressed: () async {
                _showDeleteConfirmationDialog(context, clubService);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 모임 삭제 확인 다이얼로그
  void _showDeleteConfirmationDialog(BuildContext context, ClubService clubService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('모임 삭제'),
          content: const Text('정말로 모임을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
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
                  await clubService.deleteClub(club.id); // 모임 삭제 API 호출
                  Get.offAllNamed('/home', arguments: {'initialIndex': 2});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임이 삭제되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모임 삭제에 실패했습니다. 다시 시도해주세요.')),
                  );
                }
              },
              child: const Text(
                '삭제',
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

  const SettingsButton({super.key, 
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
