import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerStatefulWidget 사용을 위한 패키지
import 'package:golbang/services/group_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/widgets/sections/group_item.dart';
import 'package:golbang/pages/club/club_create_page.dart';
import 'package:golbang/pages/community/community_main.dart';
import '../../repoisitory/secure_storage.dart';

class ClubMainPage extends ConsumerStatefulWidget {
  const ClubMainPage({super.key});

  @override
  _GroupMainPageState createState() => _GroupMainPageState();
}

class _GroupMainPageState extends ConsumerState<ClubMainPage> {
  final PageController _pageController = PageController();
  List<Group> allGroups = []; // 전체 그룹 리스트
  List<Group> filteredGroups = []; // 필터링된 그룹 리스트
  bool isLoading = true;
  late GroupService groupService;

  // Set the number of items per page as a configurable variable
  static const int itemsPerPage = 9;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(secureStorageProvider);
    groupService = GroupService(storage);
    _fetchGroups(); // 그룹 데이터를 초기화 시 가져옴
  }

  // Fetch groups once
  Future<void> _fetchGroups() async {
    try {
      List<Group> groups = await groupService.getUserGroups(); // 백엔드에서 그룹 데이터 가져옴
      setState(() {
        allGroups = groups; // 그룹 데이터를 전체 리스트에 설정
        filteredGroups = groups; // 초기에는 모든 그룹 표시
        isLoading = false;
      });
    } catch (e) {
      log("Error fetching groups: $e");
      setState(() {
        isLoading = false;
      });
    }
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
          double aspectRatio = screenWidth / (screenHeight * 0.6);

          return GridView.count(
            crossAxisCount: 3, // 한 줄에 3개의 아이템
            childAspectRatio: aspectRatio, // 가로:세로 비율
            mainAxisSpacing: 5, // 항목 간 세로 간격
            crossAxisSpacing: 10, // 항목 간 가로 간격
            padding: const EdgeInsets.all(5), // GridView의 내부 패딩
            children: filteredGroups
                .skip(index * itemsPerPage)
                .take(itemsPerPage)
                .map((club) {
              return Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.all(0),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityMain(
                            club: club
                        ),
                      ),
                    );
                  },
                  child: GroupItem(
                    image: club.image,
                    label: club.name,
                    isAdmin: club.isAdmin,
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 검색 필드와 타이틀
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '내 모임',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ClubCreatePage()),
                          ).then((_) {
                            _fetchGroups(); // 모임 생성 후 새로고침
                          });
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        label: const Text(
                          '모임생성',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '내 모임 검색',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 그룹 리스트
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10.0),
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
                      count: filteredGroups.isNotEmpty
                          ? (filteredGroups.length / itemsPerPage).ceil()
                          : 1, // 비어 있을 경우 기본값을 1로 설정 있을 때 기본값 설정
                      effect: const WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 하단 메시지
            Text(
              '하단의 달력 버튼을 눌러, 일정을 추가해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
