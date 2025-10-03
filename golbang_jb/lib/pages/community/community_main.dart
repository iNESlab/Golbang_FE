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
import '../../services/club_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../profile/profile_screen.dart'; // 🔧 추가: userAccountProvider import
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
  List<Member> get members => _club?.members.where((m) => m.role != 'admin' && m.statusType == 'active').toList() ?? [];
  List<Member> get admins => _club?.members.where((m) => m.role == 'admin' && m.statusType == 'active').toList() ?? [];
  
  // 🔧 추가: 신청/취소 처리 중 상태
  bool isProcessing = false;
  
  // 🔧 추가: 현재 사용자의 클럽 상태 확인
  String? get _currentUserStatus {
    final userAccount = ref.watch(userAccountProvider);
    if (userAccount == null || _club == null) return null;
    return _club!.getCurrentUserStatus(userAccount.id);
  }
  
  // 🔧 추가: 현재 사용자가 초대받은 상태인지 확인
  bool get _isInvited => _currentUserStatus == 'invited';
  
  // 🔧 추가: 현재 사용자가 신청한 상태인지 확인
  bool get _isApplied => _currentUserStatus == 'applied';
  
  // 🔧 추가: 현재 사용자가 활성 멤버인지 확인
  bool get _isActiveMember => _currentUserStatus == 'active';

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


  // 🔧 추가: 멤버 관리 버튼 처리
  void _onMemberManagementPressed() {
    if (_club!.isAdmin) {
      // 관리자: 멤버 목록 페이지로 이동 (관리자 권한)
      context.push('/app/clubs/${_club!.id}/setting/members', extra: {'isAdmin': true});
    } else {
      // 일반 멤버: 멤버 목록 페이지로 이동 (조회만 가능)
      context.push('/app/clubs/${_club!.id}/setting/members', extra: {'isAdmin': false});
    }
  }

  // 🔧 추가: 모임 관리 버튼 처리
  void _onClubManagementPressed() {
    if (_club!.isAdmin) {
      // 관리자: 모임 설정 페이지로 이동
      context.push('/app/clubs/${_club!.id}/setting', extra: {'role': 'admin'});
    } else {
      // 일반 멤버: 멤버 설정 페이지로 이동
      context.push('/app/clubs/${_club!.id}/setting', extra: {'role': 'member'});
    }
  }

  // 🔧 기존 설정 함수 (호환성을 위해 유지)
  void _onSettingsPressed() {
    _onClubManagementPressed();
  }

  Future<void> handleBack() async {
    if(!mounted) return;

    // 🔧 수정: Navigator 에러를 피하기 위해 항상 context.go() 사용
    _navigateBasedOnFrom();
  }

  // 🔧 추가: from 값에 따라 이동하는 헬퍼 함수
  void _navigateBasedOnFrom() {
    if (widget.from == 'home') {
      // 홈에서 온 경우 홈으로 돌아가기
      context.go('/app/home');
    } else {
      // 모임홈에서 온 경우 모임홈으로 돌아가기
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


  // 🔧 추가: 초대 수락 처리
  Future<void> _acceptInvitation() async {
    try {
      final clubService = ClubService(ref.read(secureStorageProvider));
      await clubService.respondInvitation(_club!.id, 'accepted');
      
      // 🔧 추가: 수락 후 clubStateProvider 새로고침
      ref.read(clubStateProvider.notifier).fetchClubs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 수락했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        // 클럽 정보 새로고침
        ref.read(clubStateProvider.notifier).getClub(_club!.id, context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 수락 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔧 추가: 초대 거절 처리
  Future<void> _declineInvitation() async {
    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 거절'),
        content: const Text('이 클럽의 초대를 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (shouldDecline == true) {
      try {
        final clubService = ClubService(ref.read(secureStorageProvider));
        await clubService.respondInvitation(_club!.id, 'declined');
        
        // 🔧 추가: 거절 후 clubStateProvider 새로고침
        ref.read(clubStateProvider.notifier).fetchClubs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('초대를 거절했습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
          // 클럽 목록으로 돌아가기
          context.go('/app/clubs');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('초대 거절 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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

    final adminText = admins.isEmpty
        ? '관리자 • 없음'
        : admins.length > 1
            ? '관리자 • ${admins[0].name} 외 ${admins.length - 1}명'
            : '관리자 • ${admins[0].name}';

    return PopScope(
      canPop: false, // True면 PopScope동작 안함
        onPopInvoked: (didPop) async {
          // 🔧 수정: PopScope에서도 안전하게 처리
          if (!didPop) {
            await handleBack();
          }
        },
      child: Scaffold(
        body: Column(
          children: [
            // 🔹 SafeArea + 헤더 고정
            SafeArea(
              bottom: false,
              child: Container(
                height: 50, // 🔧 원래 높이로 복원
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
                      // 왼쪽: 뒤로가기 + 제목
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
                      // 오른쪽: 멤버 관리 + 모임 관리 버튼
                      Row(
                        children: [
                          // 멤버 관리 버튼
                          IconButton(
                            icon: Stack(
                              children: [
                                const Icon(Icons.people, color: Colors.white),
                                // 🔧 추가: 가입 신청 대기 중인 멤버가 있고 관리자인 경우 빨간색 원 표시
                                if (_club?.isAdmin == true && _club?.hasPendingApplications == true)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${_club?.pendingApplicationsCount ?? 0}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: _onMemberManagementPressed,
                            tooltip: '멤버 관리',
                          ),
                          // 모임 관리 버튼
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: _onClubManagementPressed,
                            tooltip: '모임 관리',
                          ),
                        ],
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
                                  Text('멤버 • ${members.length}명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  // 🔧 추가: 상태별 메시지 표시
                                  if (_isInvited) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.orange.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.mail, color: Colors.orange.shade700, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            '초대받은 상태입니다',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (_isApplied) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.blue.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.pending, color: Colors.blue.shade700, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            '가입 신청 대기 중입니다',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: isProcessing ? null : () => _cancelApplication(_club!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isProcessing ? Colors.grey : Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: isProcessing 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text("신청 취소"),
                                    ),
                                  ],
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
                              // 🔧 수정: 상태에 따른 버튼들
                              if (_isInvited) ...[
                                // 초대받은 상태: 수락/거절 버튼
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _acceptInvitation(),
                                    icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                    label: const Text(
                                      '수락',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _declineInvitation(),
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    label: const Text(
                                      '거절',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // 일반 상태: 채팅방 버튼
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _isActiveMember ? () => _goToClubChat() : null,
                                    icon: Icon(
                                      _isApplied ? Icons.pending : Icons.chat,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: Text(
                                      _isApplied ? '신청 대기' : '채팅방',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isActiveMember ? Colors.blue : Colors.grey,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  // 🔧 추가: 신청 취소 처리
  Future<void> _cancelApplication(Club club) async {
    setState(() {
      isProcessing = true;
    });
    try {
      final clubService = ClubService(ref.read(secureStorageProvider));
      await clubService.cancelApplication(club.id);
      
      // 🔧 추가: 취소 후 clubStateProvider 새로고침
      ref.read(clubStateProvider.notifier).fetchClubs();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("신청이 취소되었습니다."),
          backgroundColor: Colors.orange,
        ),
      );
      // 🔧 추가: 취소 후 페이지 나가기
      context.pop();
    } catch (e) {
      log("Error canceling application: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신청 취소 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

}
