import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/club.dart';
import '../../models/member.dart';
import '../../provider/club/club_state_provider.dart';
import 'admin_settings_page.dart';
import 'member_settings_page.dart';

class CommunityMain extends ConsumerStatefulWidget {

  const CommunityMain({super.key, 
  });

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain> {
  late List<Member> members;
  Club? _club;

  void _onSettingsPressed() {
    if (_club!.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminSettingsPage(clubId: _club!.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberSettingsPage(clubId: _club!.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _club = ref.watch(clubStateProvider.select((s) => s.selectedClub));
    if (_club == null) {
      return const Center(child: CircularProgressIndicator());
    }
    log('뒤로가기11');


    members = _club!.members.where((m) => m.role != 'admin').toList() ?? [];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        log('뒤로가기22');
        await ref.read(clubStateProvider.notifier).fetchClubs();
        //TODO: 어째서인지, didPop이 계속 TRUe라 이렇게 위치하게 되었습니다.
        //PopScope 좀더 공부해서 바꿔야함..
        if (didPop) {
          return;
        }
        log('뒤로가기33');

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _club!.image.contains('https') // 문자열 검사
                          ? NetworkImage(_club!.image) // 네트워크 이미지
                          : AssetImage(_club!.image) as ImageProvider, // 로컬 이미지
                      fit: BoxFit.cover, // 이미지 맞춤 설정
                    ),
                  ),
                ),
                Container(
                  height: 200,
                  color: Colors.black.withOpacity(0.5),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _onSettingsPressed,
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 10,
                  child: Text(
                    _club!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft, // 전체 내용을 왼쪽 정렬
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯들을 왼쪽 정렬
                  children: [
                    Text(
                      '관리자: ${_club!.getAdminNames().join(', ')}', // 여러 관리자 이름 표시
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8), // 텍스트 간 간격 추가
                    Text(
                      '멤버: ${members.isNotEmpty
                          ? members.map((member) => member.name).join(', ')
                          : '새로운 멤버를 초대해주세요'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

}
