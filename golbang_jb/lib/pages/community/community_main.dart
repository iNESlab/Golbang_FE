import 'dart:developer';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/club.dart';
import '../../models/member.dart';
import '../../models/event.dart';
import '../../models/profile/club_profile.dart';
import '../../provider/club/club_state_provider.dart';
import '../../global/PrivateClient.dart';
// 🚫 라디오 기능 비활성화 - 안드로이드에서 사용하지 않음
// import '../../providers/global_radio_provider.dart';

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
  //   {
  //     'author': '윤성문',
  //     // 'profileImage': 'assets/images/sample_profile.png',
  //     'time': '2024년 7월 31일 오후 1시',
  //     'content': '오늘은 정말 즐거운 시간이었어요!',
  //     'image': null,
  //     'likes': 2,
  //     'comments': [],
  //   },
  //   {
  //     'author': '윤성문',
  //     // 'profileImage': 'assets/images/sample_profile.png',
  //     'time': '2024년 7월 31일 오후 1시',
  //     'content': '오늘은 정말 즐거운 시간이었어요!',
  //     'image': null,
  //     'likes': 2,
  //     'comments': [],
  //   },
  //   {
  //     'author': '고중범',
  //     // 'profileImage': 'assets/images/sample_profile.png',
  //     'time': '2024년 7월 31일 오후 1시',
  //     'content': '오늘은 정말 즐거운 시간이었어요!',
  //     'image': null,
  //     'likes': 2,
  //     'comments': [],
  //   },
  //
  //   {
  //     'author': '홍길동',
  //     // 'profileImage': 'assets/images/sample_profile.png',
  //     'time': '2024년 7월 31일 오후 1시',
  //     'content': '오늘은 정말 즐거운 시간이었어요!',
  //     'image': null,
  //     'likes': 2,
  //     'comments': [],
  //   },
  //   {
  //     'author': '김영희',
  //     // 'profileImage': 'assets/images/sample_profile.png',
  //     'time': '2024년 7월 30일 오후 4시',
  //     'content': '다음 모임은 언제인가요?',
  //     'image': null,
  //     'likes': 5,
  //     'comments': [],
  //   },
  ];


  void _onSettingsPressed() {

    if (_club!.isAdmin) {
      log('clubId: ${_club!.id}');
      context.push('/app/clubs/${_club!.id}/setting', extra: {'role': 'admin'});
    } else {
      context.push('/app/clubs/${_club!.id}/setting', extra: {'role': 'member'});
    }
  }

  Future<void> handleBack() async {
    if(!mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/clubs');
    }
  }

  // 🚫 라디오 기능 비활성화 - 안드로이드에서 사용하지 않음
  /*
  // 🎵 RTMP 라디오 토글 메서드
  void _toggleRadio() async {
    try {
      final radioState = ref.read(globalRadioProvider);
      final radioNotifier = ref.read(globalRadioProvider.notifier);
      final clubName = _club?.name ?? '클럽';
      final clubId = _club?.id;

      if (clubId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 클럽 정보를 찾을 수 없습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (radioState.isConnected && radioState.currentClubId == clubId) {
        // 현재 클럽의 라디오 정지
        await radioNotifier.stopRadio();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📻 RTMP 라디오를 정지했습니다'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // RTMP 라디오 시작
        final success = await radioNotifier.startRadio(
          clubId,
          '$clubName 라디오',
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📻 RTMP 라디오를 시작했습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // 에러 메시지는 globalRadioProvider에서 제공
          final errorMsg = radioState.errorMessage ?? '라디오 시작에 실패했습니다';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

    } catch (e) {
      log('RTMP 라디오 토글 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 라디오 오류: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  */

  // 🔧 추가: 통합 클럽 채팅방으로 이동
  void _goToClubChat() {
    // 클럽 채팅방은 club_${clubId} 형식으로 생성
    final chatRoomId = 'club_${_club!.id}';

    // Club을 ClubProfile로 변환
    final clubProfile = ClubProfile(
      clubId: _club!.id,
      name: _club!.name,
      image: _club!.image,
    );

    // 임시 이벤트 객체 생성 (채팅방 ID만 필요)
    final tempEvent = Event(
      eventId: _club!.id,
      memberGroup: 0, // 기본값
      eventTitle: '${_club!.name} 채팅방',
      site: '클럽 채팅방',
      startDateTime: DateTime.now(),
      endDateTime: DateTime.now().add(const Duration(hours: 1)),
      repeatType: 'NONE',
      gameMode: 'SP',
      alertDateTime: '',
      participantsCount: _club!.members.length,
      partyCount: 0,
      acceptCount: _club!.members.length,
      denyCount: 0,
      pendingCount: 0,
      myParticipantId: 0,
      participants: [],
      club: clubProfile,
    );

    context.push('/app/events/${_club!.id}/chat', extra: {
      'event': tempEvent,
      'chatRoomType': 'club',
      'chatRoomId': chatRoomId,
    });
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
      canPop: false, // True면 PopScope동작 안함
        onPopInvoked: (didPop) async {
          await handleBack();
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
                            onPressed: () => handleBack()
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(adminText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('멤버 • ${_club?.members.length ?? 0}명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              TextButton(
                                onPressed: null, // 비활성화
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
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
                          const SizedBox(height: 12),
                          // 🔧 채팅방 + 라디오 버튼들
                          Row(
                            children: [
                              // 채팅방 버튼
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () => _goToClubChat(),
                                  icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                                  label: const Text(
                                    '채팅방',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 라디오 버튼 (비활성화)
                              Expanded(
                                flex: 1,
                                child: ElevatedButton.icon(
                                  onPressed: null, // 비활성화
                                  icon: const Icon(
                                    Icons.radio_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Live',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey, // 비활성화된 색상
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
