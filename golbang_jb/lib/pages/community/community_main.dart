import 'dart:developer';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/club.dart';
import '../../models/member.dart';
import '../../provider/club/club_state_provider.dart';

class CommunityMain extends ConsumerStatefulWidget {
  final int? clubId;
  final String? from;
  const CommunityMain({super.key, this.clubId, this.from});

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain> {
  // ✅ 여기에 getter들 선언
  Club? get _club => ref.watch(clubStateProvider.select((s) => s.selectedClub));
  List<Member> get members => _club?.members.where((m) => m.role != 'admin').toList() ?? [];
  List<Member> get admins => _club?.members.where((m) => m.role == 'admin').toList() ?? [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.clubId != null) { // 상세에 들어오면 한번은 새로고침하기
      Future.microtask(() {
        if (!mounted) return;
        ref.read(clubStateProvider.notifier).getClub(widget.clubId!, context);
      });
    }
  }


  final List<Map<String, dynamic>> dummyPosts = [
    {
      'author': '윤성문',
      // 'profileImage': 'assets/images/sample_profile.png',
      'time': '2024년 7월 31일 오후 1시',
      'content': '오늘은 정말 즐거운 시간이었어요!',
      'image': null,
      'likes': 2,
      'comments': [],
    },
    {
      'author': '윤성문',
      // 'profileImage': 'assets/images/sample_profile.png',
      'time': '2024년 7월 31일 오후 1시',
      'content': '오늘은 정말 즐거운 시간이었어요!',
      'image': null,
      'likes': 2,
      'comments': [],
    },
    {
      'author': '고중범',
      // 'profileImage': 'assets/images/sample_profile.png',
      'time': '2024년 7월 31일 오후 1시',
      'content': '오늘은 정말 즐거운 시간이었어요!',
      'image': null,
      'likes': 2,
      'comments': [],
    },

    {
      'author': '홍길동',
      // 'profileImage': 'assets/images/sample_profile.png',
      'time': '2024년 7월 31일 오후 1시',
      'content': '오늘은 정말 즐거운 시간이었어요!',
      'image': null,
      'likes': 2,
      'comments': [],
    },
    {
      'author': '김영희',
      // 'profileImage': 'assets/images/sample_profile.png',
      'time': '2024년 7월 30일 오후 4시',
      'content': '다음 모임은 언제인가요?',
      'image': null,
      'likes': 5,
      'comments': [],
    },
  ];


  void _onSettingsPressed() {

    if (_club!.isAdmin) {
      log('clubId: ${_club!.id}');
      context.push('/clubs/${_club!.id}/setting', extra: {'role': 'admin'});
    } else {
      context.push('/clubs/${_club!.id}/setting', extra: {'role': 'member'});
    }
  }

  Future<void> handleBack() async {
    if(!mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/clubs');
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
      canPop: true,
      onPopInvoked: (didPop) async {
        await handleBack(); //TODO: 시스템 뒤로가기 안됨
      },
      child: Scaffold(
        body: Column(
          children: [
            // 🔹 SafeArea + 헤더 고정
            SafeArea(
              bottom: false,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _club!.image.contains('https')
                        ? NetworkImage(_club!.image)
                        : AssetImage(_club!.image) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.pop(),
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
              ),
            ),

            // 🔹 아래는 스크롤 되는 부분
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 관리자 정보
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(adminText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('멤버 • ${members.length}명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.push('/clubs/${_club!.id}/new-post'),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('글쓰기'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4,),
                    // 게시물 리스트
                    ...dummyPosts.map((post) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(backgroundImage: AssetImage('assets/images/founder.webp')),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(post['time'], style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.more_vert),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(post['content']),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye, size: 16),
                                const SizedBox(width: 4),
                                Text('${post['likes']}'),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

}
