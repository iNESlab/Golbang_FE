import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerStatefulWidget 사용을 위한 패키지
import 'package:golbang/services/group_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/widgets/sections/group_item.dart';
import 'package:golbang/pages/group/group_create.dart';
import 'package:golbang/pages/community/community_main.dart';
import '../../repoisitory/secure_storage.dart';
import 'package:get/get.dart';

class GroupMainPage extends ConsumerStatefulWidget {
  @override
  _GroupMainPageState createState() => _GroupMainPageState();
}

class _GroupMainPageState extends ConsumerState<GroupMainPage> {
  final PageController _pageController = PageController();
  List<Group> allGroups = []; // 전체 그룹 리스트
  List<Group> filteredGroups = []; // 필터링된 그룹 리스트
  bool isLoading = true;

  // Set the number of items per page as a configurable variable
  static const int itemsPerPage = 6;

  Future<void> _checkAndNavigateToCommunity() async {
    final communityId = Get.arguments?['communityId'];

    if (communityId != null) {

      // groupService를 사용해 그룹 정보를 가져옴
      final storage = ref.read(secureStorageProvider);
      final GroupService groupService = GroupService(storage);
      var targetGroupId = Get.arguments?['communityId'];

      if (targetGroupId != null) {
        List<Group> group = await groupService.getGroupInfo(targetGroupId);
        final communityName = group[0].name;
        final communityImage = group[0].image;

        Get.offNamed('/home', arguments: {'communityId': null});
        // UI가 빌드된 후 CommunityMain 페이지로 이동
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityMain(
                communityName: communityName,
                communityImage: communityImage ?? '', // 이미지가 없을 때 대비
              ),
            ),
          );
        });
      }
    }
  }

  // Fetch groups once
  Future<void> _fetchGroups() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final GroupService groupService = GroupService(storage);
      List<Group> groups = await groupService.getUserGroups();
      setState(() {
        allGroups = groups;
        filteredGroups = groups; // 초기에는 모든 그룹 표시
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching groups: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndNavigateToCommunity();
    _fetchGroups(); // 그룹 데이터를 초기화 시 가져옴
  }

  // 그룹 데이터를 페이지로 나누는 함수 (필터링된 그룹 사용)
  List<Widget> _buildGroupPages() {
    int pageCount = (filteredGroups.length / itemsPerPage).ceil();

    return List.generate(pageCount, (index) {
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10),
        children: filteredGroups
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
                      communityImage: group.image!,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: GroupItem(
                      image: group.image!,
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
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Text('내 모임',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GroupCreatePage()),
                      ).then((_) {
                        _fetchGroups(); // 모임 생성 후 새로고침
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
                  onChanged: (value) {
                    setState(() {
                      filteredGroups = allGroups
                          .where((group) => group.name
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10.0),
                height: 320, // 높이를 약간 늘려서 6개의 그룹을 표시할 공간 확보
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        children: _buildGroupPages(),
                      ),
                    ),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: (filteredGroups.length / itemsPerPage).ceil(),
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
      ],
    );
  }
}
