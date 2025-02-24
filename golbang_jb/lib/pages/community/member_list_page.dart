import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/member_profile.dart';
import '../../../models/profile/get_all_user_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';
import '../../services/club_service.dart';
import '../../widgets/common/circular_default_person_icon.dart';
import '../../widgets/sections/member_dialog.dart';

class MemberListPage extends ConsumerStatefulWidget {
  final int clubId;

  const MemberListPage({super.key, required this.clubId});

  @override
  _MemberListPageState createState() => _MemberListPageState();
}

class _MemberListPageState extends ConsumerState<MemberListPage> {
  List<GetAllUserProfile> newMembers = [];
  List<GetAllUserProfile> selectedMembers = [];
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
      List<ClubMemberProfile> fetchedMembers = await _clubMemberService.getClubMemberProfileList(club_id: widget.clubId);

      setState(() {
        oldMembers = fetchedMembers;
        // 🔹 기존 멤버들을 selectedMembers에 미리 추가
        selectedMembers = oldMembers
            .map((m) => GetAllUserProfile(
          userId: m.name,
          id: m.id,
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
        return MemberDialog(
          selectedMembers: selectedMembers,
          isAdminMode: false,
          selectedAdmins: [],
        );
      },
    ).then((result) async {
      if (result != null) {
        newMembers = result.where((m)=>
        !oldMembers.any((old) => old.id == m.id) // 🔥 oldMembers에 없는 멤버만 남기기
        ).toList();

        if (newMembers.isNotEmpty){
          final clubService = ClubService(ref.read(secureStorageProvider));
          await clubService.inviteMembers(widget.clubId, newMembers);
          _fetchMembers();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 조회'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showMemberDialog,
          ),

        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: oldMembers.length,
        itemBuilder: (context, index) {
          final member = oldMembers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: member.profileImage.startsWith('https')
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMemberDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}