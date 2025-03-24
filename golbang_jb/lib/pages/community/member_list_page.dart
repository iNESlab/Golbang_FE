import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/member_profile.dart';
import '../../../models/profile/get_all_user_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';
import '../../provider/club/club_state_provider.dart';
import '../../services/club_service.dart';
import '../../widgets/common/circular_default_person_icon.dart';
import '../../widgets/sections/community_member_dialog.dart';

class MemberListPage extends ConsumerStatefulWidget {
  final int clubId;
  final bool isAdmin;

  const MemberListPage({
    super.key,
    required this.clubId,
    required this.isAdmin,
  });

  @override
  _MemberListPageState createState() => _MemberListPageState();
}

class _MemberListPageState extends ConsumerState<MemberListPage> {
  List<GetAllUserProfile> newMemberUsers = [];
  List<GetAllUserProfile> selectedMemberUsers = [];
  List<ClubMemberProfile> oldMembers = [];
  late ClubMemberService _clubMemberService;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _clubMemberService = ClubMemberService(ref.read(secureStorageProvider));
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      List<ClubMemberProfile> fetchedMembers = await _clubMemberService
          .getClubMemberProfileList(club_id: widget.clubId);

      setState(() {
        oldMembers = fetchedMembers;
        selectedMemberUsers = oldMembers
            .map((m) => GetAllUserProfile(
          accountId: m.accountId,
          name: m.name,
          profileImage: m.profileImage,
        ))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      log("Error fetching members: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMemberDialog() {
    showDialog<List<GetAllUserProfile>>(
      context: context,
      builder: (BuildContext context) {
        return UserDialog(
          selectedUsers: selectedMemberUsers,
          newSelectedUsers: newMemberUsers,
          isAdminMode: false,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          selectedMemberUsers = oldMembers
              .map((m) => GetAllUserProfile(
            accountId: m.accountId,
            name: m.name,
            profileImage: m.profileImage,
          )).toList();
          log('result: ${result.length}');
          newMemberUsers =
              result.where((e) => !oldMembers.any((old) => old.accountId == e.accountId)).toList();
          log('newMemberUsers: $newMemberUsers');
        });
      }
    });
  }
  /// 멤버 추방 다이얼로그
  void _showKickDialog(ClubMemberProfile member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("멤버 추방"),
          content: Text("${member.name}님을 추방하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _kickMember(member);
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text("추방"),
            ),
          ],
        );
      },
    );
  }

  /// 멤버 추방 함수
  Future<void> _kickMember(ClubMemberProfile member) async {
    final clubService = ClubService(ref.read(secureStorageProvider));
    await clubService.removeMember(widget.clubId, member.memberId);
    ref.read(clubStateProvider.notifier).removeMemberFromSelectedClub(member.memberId);

    setState(() {
      oldMembers.removeWhere((m) => m.memberId == member.memberId);
      selectedMemberUsers.removeWhere((e) => e.accountId == member.accountId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (newMemberUsers.isNotEmpty) {
          final shouldExit = await _confirmInviteOnExit();
          return shouldExit; // 다이얼로그 결과에 따라 페이지 이동 여부 결정
        }
        return true; // 새 멤버가 없으면 바로 이전 페이지로
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('멤버 조회'),
          centerTitle: true,
          actions: [
            if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showMemberDialog,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            if (oldMembers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // 여러 줄 고려
                  children: [
                    const Text(
                      "기존 멤버",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.isAdmin)
                      const Expanded(
                        child: Text(
                          "멤버를 눌러 추방할 수 있습니다",
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2, // 길 경우 두 줄까지 허용
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 실제 멤버 리스트 타일들
              ...oldMembers.map((member) => _buildMemberTile(member)),
            ],

            if (newMemberUsers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "새로운 멤버",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "뒤로 가기를 누르면 완료됩니다",
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              ...newMemberUsers.map((member) => _buildNewMemberTile(member)),
            ],
            if (newMemberUsers.isEmpty && oldMembers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("멤버가 없습니다.",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              ),
          ],
        ),
        floatingActionButton: widget.isAdmin
            ? FloatingActionButton(
          onPressed: _showMemberDialog,
          child: const Icon(Icons.person_add),
        )
            : null, // 어드민이 아닐 경우 버튼 숨김
      ),
    );
  }

  /// 뒤로 나갈 때 초대 여부 확인하는 다이얼로그
  Future<bool> _confirmInviteOnExit() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("멤버 초대"),
          content: Text("${newMemberUsers.length}명을 초대하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // 초대 안 하고 나가기
              },
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _inviteMembers();
                Navigator.pop(context, false); // 다이얼로그 닫기
                Navigator.pop(context); // 이전 페이지로 이동
              },
              child: const Text("초대"),
            ),
          ],
        );
      },
    ) ?? true; // 다이얼로그가 강제로 닫히면 기본적으로 나가기 허용
  }

  /// 초대 실행 함수
  Future<void> _inviteMembers() async {
    final clubService = ClubService(ref.read(secureStorageProvider));
    final newMembers = await clubService.inviteMembers(widget.clubId, newMemberUsers);
    ref.read(clubStateProvider.notifier).updateSelectedClubMembers(newMembers);
    log('newMembers number: ${newMembers.length}');

    setState(() {
      oldMembers.addAll(newMembers.map((m) => ClubMemberProfile(
        memberId: m.memberId, // 임시 처리
        name: m.name,
        role: "member",
        profileImage: m.profileImage,
        accountId: m.accountId,
      )));
      selectedMemberUsers.addAll(newMemberUsers);
      newMemberUsers.clear();
    });
  }

  Widget _buildMemberTile(dynamic member) {
    final bool isAdminMember = member.role == "admin"; // 어드민 여부 체크

    return InkWell(
      onLongPress: () {
        if (widget.isAdmin && !isAdminMember) {
          _showKickDialog(member); // 일반 멤버만 추방 가능
        }
      },
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isAdminMember ? Colors.green : Colors.transparent, // 어드민이면 초록 테두리
              width: 3,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: (member.profileImage != null && member.profileImage.startsWith('https'))
                ? ClipOval(
              child: Image.network(
                member.profileImage,
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return const CircularIcon();
                },
              ),
            )
                : const CircularIcon(),
          ),
        ),
        title: Text(member.name),
      ),
    );
  }


  Widget _buildNewMemberTile(dynamic member) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: (member.profileImage != null && member.profileImage.startsWith('https'))
            ? ClipOval(
          child: Image.network(
            member.profileImage,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
            errorBuilder: (context, error, stackTrace) {
              return const CircularIcon();
            },
          ),
        )
            : const CircularIcon(),
      ),
      title: Text(member.name),
    );
  }
}