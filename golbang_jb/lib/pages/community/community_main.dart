import 'package:flutter/material.dart';
import 'package:golbang/api.dart';
import 'package:golbang/global_config.dart';
import 'package:golbang/pages/community/community_post.dart';
import 'package:golbang/widgets/sections/post_item.dart';
import 'admin_settings_page.dart';
import 'member_settings_page.dart';

class CommunityMain extends StatefulWidget {
  final int communityID;
  final String communityName;
  final String communityImage;
  final String adminName;
  final bool isAdmin; // 관리자 여부 추가

  CommunityMain({
    required this.communityID,
    required this.communityName,
    required this.communityImage,
    required this.adminName,
    required this.isAdmin, // 관리자 여부를 받도록 수정
  });

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends State<CommunityMain> {
  late List<Map<String, dynamic>> posts;
  late List<Map<String, dynamic>> members;

  @override
  void initState() {
    super.initState();
    final groupId = _getGroupId();
    posts = getGroupPosts(groupId)['data'];
    members = [];
    // members = getGroupMembers(groupId)['data'];

    // 로그에 데이터 출력
    print('Posts: $posts');
    print('Members: $members');
  }

  int _getGroupId() {
    // final group = GlobalConfig.groups.firstWhere((group) => group.name == widget.communityName);
    return 1;
  }

  void _onSettingsPressed() {
    if (widget.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminSettingsPage(clubId: widget.communityID,), // 관리자 페이지
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberSettingsPage(clubId: widget.communityID,), // 멤버 설정 페이지
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
                    image: AssetImage(widget.communityImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: _onSettingsPressed, // 설정 버튼 클릭 시 동작
                ),
              ),
              Positioned(
                bottom: 20,
                left: 10,
                child: Text(
                  widget.communityName,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관리자: ${widget.adminName}', // 관리자 이름을 동적으로 표시
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '멤버: ${members.map((member) => member['name']).join(', ')}', // 멤버 이름 전체 표시
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Container(); // 필요한 경우 PostItem 사용
                // return PostItem(
                //   post: post,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => CommunityPost(post: post),
                //       ),
                //     );
                //   },
                // );
              },
            ),
          ),
        ],
      ),
    );
  }
}
