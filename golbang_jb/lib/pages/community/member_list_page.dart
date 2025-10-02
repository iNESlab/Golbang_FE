import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/models/profile/get_all_user_profile.dart';
import 'package:golbang/models/profile/member_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';
import '../../services/club_service.dart';
import '../../widgets/common/circular_default_person_icon.dart';
import '../../widgets/sections/community_member_dialog.dart';
class MemberListPage extends ConsumerStatefulWidget {
  final int clubId;
  final bool isAdmin;
  final int initialTabIndex; // 🔧 추가: 초기 탭 인덱스

  const MemberListPage({
    super.key,
    required this.clubId,
    required this.isAdmin,
    this.initialTabIndex = 0, // 🔧 기본값: 첫 번째 탭
  });

  @override
  _MemberListPageState createState() => _MemberListPageState();
}

class _MemberListPageState extends ConsumerState<MemberListPage> {
  List<ClubMemberProfile> activeMembers = [];
  List<ClubMemberProfile> pendingMembers = [];
  List<GetAllUserProfile> oldMemberUsers = [];
  bool isLoading = true;
  bool isDeleteMode = false;
  late ClubMemberService _clubMemberService;
  late ClubService _clubService;

  @override
  void initState() {
    super.initState();
    _clubMemberService = ClubMemberService(ref.read(secureStorageProvider));
    _clubService = ClubService(ref.read(secureStorageProvider));
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final fetched = await _clubMemberService.getClubMemberProfileList(clubId: widget.clubId);
      setState(() {
        oldMemberUsers = fetched.map((m)=>m.toUserProfile()).toList();
        activeMembers = fetched.where((m) => m.statusType == 'active').toList();
        pendingMembers = fetched.where((m) => m.statusType == 'invited' || m.statusType == 'applied').toList();
        isLoading = false;
      });
    } catch (e) {
      log("Error fetching members: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.isAdmin ? 2 : 0,
      initialIndex: widget.initialTabIndex, // 🔧 추가: 초기 탭 설정
      child: Scaffold(
        appBar: AppBar(
          title: const Text("멤버 관리"),
          bottom: widget.isAdmin ? TabBar(
            tabs: [
              const Tab(text: "활동 멤버"),
              if (widget.isAdmin) const Tab(text: "초대/신청 대기"),
            ],
          ): null,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildActiveList(),
            if (widget.isAdmin) _buildPendingList(),
          ],
        ),
        floatingActionButton: widget.isAdmin
            ? FloatingActionButton(
          onPressed: _showInviteDialog,
          child: const Icon(Icons.person_add),
        )
            : null,
      ),
    );
  }

  Widget _buildActiveList() {
    if (activeMembers.isEmpty) {
      return const Center(child: Text("활동 멤버가 없습니다."));
    }
    return ListView(
      children: activeMembers.map((m) => _buildActiveTile(m)).toList(),
    );
  }

  Widget _buildPendingList() {
    if (pendingMembers.isEmpty) {
      return const Center(child: Text("가입 대기 멤버가 없습니다."));
    }
    return ListView(
      children: pendingMembers.map((m) => _buildPendingTile(m)).toList(),
    );
  }


  Widget _buildActiveTile(ClubMemberProfile member) {
    final isAdminMember = member.role == "admin";

    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          backgroundImage: (member.profileImage.isNotEmpty &&
              member.profileImage.startsWith('http'))
              ? NetworkImage(member.profileImage)
              : null,
          child: (member.profileImage.isEmpty ||
              !member.profileImage.startsWith('http'))
              ? const CircularIcon()
              : null,
        ),
        title: Text(member.name),
        subtitle: isAdminMember ? const Text("관리자") : null,
        trailing: !isAdminMember && widget.isAdmin
            ? IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            _showKickDialog(member); // ❌ X 버튼 → 모달 호출
          },
        )
            : null,
      ),
    );
  }

// 👉 Pending 멤버 타일
  Widget _buildPendingTile(ClubMemberProfile member) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          backgroundImage: (member.profileImage.isNotEmpty &&
              member.profileImage.startsWith('http'))
              ? NetworkImage(member.profileImage)
              : null,
          child: (member.profileImage.isEmpty ||
              !member.profileImage.startsWith('http'))
              ? const CircularIcon()
              : null,
        ),
        title: Text(member.name),
        subtitle: Text(member.statusType == 'invited' ? "초대됨" : "가입 신청"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.statusType == 'applied') ...[
              // 가입 신청자: 승인/거절 버튼
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  try {
                    await _clubService.approveApplication(widget.clubId, member.accountId);
                    setState(() {
                      pendingMembers.removeWhere((m) => m.memberId == member.memberId);
                      activeMembers.add(member.copyWith(statusType: 'active'));
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${member.name}님의 가입을 승인했습니다'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch(e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('가입 승인 실패: $e'),
                          backgroundColor: Colors.red,
                        ));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  try {
                    await _clubService.rejectApplication(widget.clubId, member.accountId);
                    setState(() {
                      pendingMembers.removeWhere((m) => m.memberId == member.memberId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${member.name}님의 가입을 거절했습니다'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch(e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('가입 거절 실패: $e'),
                          backgroundColor: Colors.red,
                        ));
                  }
                },
              ),
            ] else if (member.statusType == 'invited') ...[
              // 초대된 사용자: 취소 버튼
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () async {
                  try {
                    await _clubService.cancelInvitation(widget.clubId, member.accountId);
                    setState(() {
                      pendingMembers.removeWhere((m) => m.memberId == member.memberId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${member.name}님의 초대를 취소했습니다'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch(e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('초대 취소 실패: $e'),
                          backgroundColor: Colors.red,
                        ));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 멤버 추방 다이얼로그
  void _showKickDialog(ClubMemberProfile member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("멤버 추방"),
        content: Text("${member.name}님을 추방하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _clubService.removeMember(widget.clubId, member.memberId);
              setState(() {
                activeMembers.removeWhere((m) => m.memberId == member.memberId);
              });
              context.pop();
            },
            child: const Text("추방"),
          ),
        ],
      ),
    );
  }

  /// 멤버 초대 다이얼로그
  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return UserDialog(
          selectedUsers: oldMemberUsers, // 이미 선택된 유저
          newSelectedUsers: const [], // 새로 초대한 유저
          isAdminMode: false,
        );
      },
    ).then((result) async {
      if (result != null && result.isNotEmpty) {
        final newMemberUsers =
            result.where((e) => !oldMemberUsers.any((old) => old.accountId == e.accountId)).toList();
        final newMembers = await _clubService.inviteMembers(widget.clubId, newMemberUsers);
        setState(() {
          activeMembers.addAll(newMembers.map((m) => m.toProfile().copyWith(statusType: 'active')));
        });
      }
    });
  }
}