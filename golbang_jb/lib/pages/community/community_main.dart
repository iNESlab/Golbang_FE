import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import 'admin_settings_page.dart';
import 'member_settings_page.dart';

class CommunityMain extends StatefulWidget {
  final Group club;

  const CommunityMain({super.key, 
    required this.club
  });

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends State<CommunityMain> {
  late List<Member> members;

  @override
  void initState() {
    super.initState();
    members = widget.club.members.where((m)=>m.role != 'admin').toList();
  }

  void _onSettingsPressed() {
    if (widget.club.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminSettingsPage(club: widget.club),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberSettingsPage(clubId: widget.club.id),
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
                    image: widget.club.image.contains('https') // 문자열 검사
                        ? NetworkImage(widget.club.image) // 네트워크 이미지
                        : AssetImage(widget.club.image) as ImageProvider, // 로컬 이미지
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
                  widget.club.name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft, // 전체 내용을 왼쪽 정렬
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯들을 왼쪽 정렬
                children: [
                  Text(
                    '관리자: ${widget.club.getAdminNames().join(', ')}', // 여러 관리자 이름 표시
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8), // 텍스트 간 간격 추가
                  Text(
                    '멤버: ${members.isNotEmpty
                        ? members.map((member) => member.name).join(', ')
                        : '새로운 멤버를 초대해주세요'}',
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
