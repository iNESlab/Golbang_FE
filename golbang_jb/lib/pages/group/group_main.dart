import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:golbang/api.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/widgets/sections/group_item.dart';
import 'package:golbang/pages/group/group_create.dart';
import 'package:golbang/pages/community/community_main.dart';

class GroupMainPage extends StatefulWidget {
  @override
  _GroupMainPageState createState() => _GroupMainPageState();
}

class _GroupMainPageState extends State<GroupMainPage> {
  final PageController _pageController = PageController();

  List<Widget> _buildGroupPages(List<Group> groupData) {
    int itemsPerPage = 3;
    int pageCount = (groupData.length / itemsPerPage).ceil();

    return List.generate(pageCount, (index) {
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10),
        children: groupData
            .skip(index * itemsPerPage)
            .take(itemsPerPage)
            .map((group) {
          return Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: EdgeInsets.all(0),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityMain(
                      communityName: group.name,
                      communityImage: group.image,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: GroupItem(
                      image: group.image,
                      label: group.name.length > 5
                          ? group.name.substring(0, 5) + '...'
                          : group.name,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Simulate fetching user token
    String userToken = 'token_john_doe';
    var userGroupsData = getUserGroups(userToken);
    print(userGroupsData);
    List<Group> userGroups = userGroupsData;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Text('내 모임',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GroupCreatePage()),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    icon: Icon(Icons.add_circle, color: Colors.green),
                    label: Text('모임생성',
                        style: TextStyle(fontSize: 16, color: Colors.green)),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '모임명 검색',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        children: _buildGroupPages(userGroups),
                      ),
                    ),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: (userGroups.length / 3).ceil(),
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        // 주석 처리된 공지사항 부분
        /*
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('공지사항',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView(
                    children: GlobalConfig.announcementData.map((announcement) {
                      return Dismissible(
                        key: Key(announcement['title']!),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('읽음', style: TextStyle(color: Colors.white)),
                        ),
                        onDismissed: (direction) {
                          // Handle dismissal here
                        },
                        child: AnnouncementItem(
                          title: announcement['title']!,
                          date: announcement['date']!,
                          content: announcement['content']!,
                          image: announcement['image']!,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        */
      ],
    );
  }
}
