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
              backgroundColor: Colors.transparent,
              child: member.profileImage != null
                  ? ClipOval(
                  child: Image.network(
                    member.profileImage!,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildCircularIcon(); // 에러 시 동그란 아이콘 표시
                    },
                  )
              )
              : _buildCircularIcon(),
            ),
            title: Text(member.name),
          );
        },
      ),
    );
  }

  Widget _buildCircularIcon() {
    return ClipOval(
      child: Container(
        color: Colors.grey[300], // 배경색 (선택사항)
        width: 60,
        height: 60,
        child: const Icon(
          Icons.person,
          size: 30,
          color: Colors.grey,
        ),
      ),
    );
  }
}
