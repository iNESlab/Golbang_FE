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
    int? communityId = Get.arguments?['communityId'];

    if (communityId != -1) {
      final storage = ref.read(secureStorageProvider);
      final GroupService groupService = GroupService(storage);
      List<Group> group = await groupService.getGroupInfo(communityId!);

      if (group != null) {
        final communityName = group[0].name;
        final communityImage = group[0].image ?? ''; // 이미지가 없을 때 대비
        final adminName = group[0].getAdminName(); // 관리자의 이름 가져오기

        Get.arguments?['communityId'] = -1;
        // UI가 빌드된 후 CommunityMain 페이지로 이동
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityMain(
                communityName: communityName,
                communityImage: communityImage,
                adminName: adminName,  // 관리자의 이름 전달
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
      List<Group> groups = await groupService.getUserGroups(); // 백엔드에서 그룹 데이터 가져옴
      setState(() {
        allGroups = groups; // 그룹 데이터를 전체 리스트에 설정
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
      return LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = MediaQuery.of(context).size.width;
          double screenHeight = MediaQuery.of(context).size.height;

          // childAspectRatio를 화면 크기에 따라 설정
          double aspectRatio = screenWidth / (screenHeight * 0.7);

          return GridView.count(
            crossAxisCount: 3, // 한 줄에 3개의 아이템
            childAspectRatio: aspectRatio, // 가로:세로 비율
            mainAxisSpacing: 10, // 항목 간 세로 간격
            crossAxisSpacing: 10, // 항목 간 가로 간격
            padding: EdgeInsets.all(5), // GridView의 내부 패딩
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
                          adminName: group.getAdminName(),
                        ),
                      ),
                    );
                  },
                  child: GroupItem(
                    image: group.image!,
                    label: group.name,
                    isAdmin: group.isAdmin,
                  ),
                ),
              );
            }).toList(),
          );
        },
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
                height: MediaQuery.of(context).size.height * 0.48, // 화면 높이에 비례한 값
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Expanded( // 내부 콘텐츠가 공간을 적절히 차지하도록 확장
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
        SizedBox(height: 10),
        Text(
          '이벤트 페이지로 이동해 모임의 이벤트를 생성해보세요!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Divider(),
      ],
    );
  }
}
