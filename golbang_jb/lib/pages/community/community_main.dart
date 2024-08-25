import 'package:flutter/material.dart';
import 'package:golbang/api.dart';
import 'package:golbang/global_config.dart';
import 'package:golbang/pages/community/community_post.dart';
import 'package:golbang/widgets/sections/post_item.dart';

class CommunityMain extends StatefulWidget {
  final String communityName;
  final String communityImage;

  CommunityMain({required this.communityName, required this.communityImage});

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
    members = getGroupMembers(groupId)['data'];

    // 로그에 데이터 출력
    print('Posts: $posts');
    print('Members: $members');
  }

  int _getGroupId() {
    final group = GlobalConfig.groups.firstWhere((group) => group.name == widget.communityName);
    return group.id;
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
                right: 60,
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // 글쓰기 버튼 클릭 시 동작
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    // 설정 버튼 클릭 시 동작
                  },
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
                      '관리자: 김민정, 정수미', // 이 부분은 데이터로 대체할 수 있습니다.
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '멤버: ${members.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // 멤버 추가 버튼 클릭 시 동작
                  },
                  child: Text('멤버 추가'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostItem(
                  post: post,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityPost(post: post),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
