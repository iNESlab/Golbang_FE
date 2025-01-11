import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/profile/member_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';

class MemberListPage extends ConsumerStatefulWidget {
  final int clubId;

  const MemberListPage({super.key, required this.clubId});

  @override
  _MemberListPageState createState() => _MemberListPageState();
}

class _MemberListPageState extends ConsumerState<MemberListPage> {
  List<ClubMemberProfile> members = [];
  bool isLoading = true;
  late ClubMemberService _clubMemberService;

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
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching members: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 조회'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: member.profileImage.startsWith('http')
                  ? NetworkImage(member.profileImage)
                  : AssetImage(member.profileImage) as ImageProvider,
            ),
            title: Text(member.name),
          );
        },
      ),
    );
  }
}
