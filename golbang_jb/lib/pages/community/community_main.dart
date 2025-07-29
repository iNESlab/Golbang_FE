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
  // ✅ 여기에 getter들 선언
  Club? get _club => ref.watch(clubStateProvider.select((s) => s.selectedClub));
  List<Member> get members => _club?.members.where((m) => m.role != 'admin').toList() ?? [];
  List<Member> get admins => _club?.members.where((m) => m.role == 'admin').toList() ?? [];

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
    if (_club == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final adminText = admins.length > 1
        ? '관리자 • ${admins[0].name} 외 ${admins.length - 1}명'
        : '관리자 • ${admins[0].name}';

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
            SafeArea(
              child: Stack(
                children: [
                  // 🔹 배경 이미지
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _club!.image.contains('https')
                            ? NetworkImage(_club!.image)
                            : AssetImage(_club!.image) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // 🔹 어둡게 오버레이
                  Container(
                    height: 50,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  // 🔹 버튼과 텍스트를 중앙 Y축에 맞추고, 좌우 정렬
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Text(
                              _club!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: _onSettingsPressed,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🔥 왼쪽/오른쪽 정렬
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '멤버 • ${members.length}명',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green, // 배경 초록색
                      foregroundColor: Colors.white, // 글자색 흰색
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 둥근 사각형
                      ),
                    ),
                      child: const Text(
                        '글쓰기',
                      )
                  ),
                ],
              ),
            ),


            Expanded(
              child: Container(
                color: Colors.grey.withOpacity(0.5),
              ),
            ),

          ],
        ),
      ),
    );
  }

}
