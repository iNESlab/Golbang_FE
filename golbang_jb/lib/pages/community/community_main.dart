import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/club_member_service.dart';
import 'package:golbang/models/profile/member_profile.dart';
import 'admin_settings_page.dart';
import 'member_settings_page.dart';

class CommunityMain extends ConsumerStatefulWidget {
  final int communityID;
  final String communityName;
  final String communityImage;
  final List<String> adminNames;
  final bool isAdmin;

  CommunityMain({
    required this.communityID,
    required this.communityName,
    required this.communityImage,
    required this.adminNames,
    required this.isAdmin,
  });

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain> {
  List<ClubMemberProfile> members = [];
  bool isLoading = true;
  late ClubMemberService _clubMemberService;

  @override
  void initState() {
    super.initState();
    _clubMemberService = ClubMemberService(ref.read(secureStorageProvider));
    fetchGroupMembers();
  }

  void fetchGroupMembers() async {
    try {
      final fetchedMembers = await _clubMemberService.getClubMemberProfileList(club_id: widget.communityID);
      setState(() {
        members = fetchedMembers;
        isLoading = false;
      });
    } catch (e) {
      log('Error fetching members: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSettingsPressed() {
    if (widget.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminSettingsPage(clubId: widget.communityID),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberSettingsPage(clubId: widget.communityID),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: widget.communityImage.contains('https') // 문자열 검사
                        ? NetworkImage(widget.communityImage) // 네트워크 이미지
                        : AssetImage(widget.communityImage) as ImageProvider, // 로컬 이미지
                    fit: BoxFit.cover, // 이미지 맞춤 설정
                  ),
                ),
              ),
              Container(
                height: 200,
                color: Colors.black.withOpacity(0.5),
              ),
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _onSettingsPressed,
                ),
              ),
              Positioned(
                bottom: 20,
                left: 10,
                child: Text(
                  widget.communityName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Align(
              alignment: Alignment.centerLeft, // 전체 내용을 왼쪽 정렬
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯들을 왼쪽 정렬
                children: [
                  Text(
                    '관리자: ${widget.adminNames.join(', ')}', // 여러 관리자 이름 표시
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8), // 텍스트 간 간격 추가
                  Text(
                    '멤버: ${members.map((member) => member.name).join(', ')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
