import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/member_profile.dart';
import '../../../models/profile/get_all_user_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';
import '../../widgets/common/circular_default_person_icon.dart';
import '../../widgets/sections/member_dialog.dart';

class MemberListPage extends ConsumerStatefulWidget {
  final int clubId;

  const MemberListPage({super.key, required this.clubId});

  @override
  _MemberListPageState createState() => _MemberListPageState();
}

class _MemberListPageState extends ConsumerState<MemberListPage> {
  List<GetAllUserProfile> selectedMembers = [];
  List<ClubMemberProfile> members = [];
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
        members = fetchedMembers;
        // 🔹 기존 멤버들을 selectedMembers에 미리 추가
        selectedMembers = members
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
      print("Error fetching members: $e");
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
          onMembersSelected: (List<GetAllUserProfile> members) {
            setState(() {
                selectedMembers = members;
            });
          },
          isAdminMode: false,
          selectedAdmins: [],
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          selectedMembers = result;
        });
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
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: member.profileImage != null
                  ? ClipOval(
                child: Image.network(
                  member.profileImage!,
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