import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/models/get_statistics_yearly.dart';
import 'package:golbang/models/get_statistics_ranks.dart';
import 'package:golbang/services/group_service.dart';
import '../../services/statistics_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../../models/group.dart'; // 그룹 모델 추가

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final SecureStorage secureStorage;
  late final StatisticsService statisticsService;
  late final GroupService groupService; // 그룹 서비스 추가
  String selectedYear = '2024';

  List<Group> groups = []; // 그룹 리스트
  Map<int, ClubStatistics> groupRankings = {}; // 그룹별 랭킹 데이터
  List<EventStatistics> _selectedEvents = []; // 클릭한 모임의 이벤트 리스트
  OverallStatistics? overallStatistics; // 전체 통계 선언
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    secureStorage = SecureStorage(storage: const FlutterSecureStorage());
    statisticsService = StatisticsService(secureStorage);
    groupService = GroupService(secureStorage); // 그룹 서비스 초기화
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // 그룹 리스트 가져오기
      groups = await groupService.getUserGroups();

      // 각 그룹별 랭킹 가져오기
      for (Group group in groups) {
        ClubStatistics? ranking = await groupService.fetchGroupRanking(group.id);
        if (ranking != null) {
          groupRankings[group.id] = ranking;
        }
      }

      // 전체 통계 가져오기
      overallStatistics = await statisticsService.fetchOverallStatistics();

      // 초기에 첫 그룹의 이벤트 리스트를 보여주기 위해 선택 (원하는 로직에 따라 변경 가능)
      if (groups.isNotEmpty && groupRankings.isNotEmpty) {
        _loadEventsForGroup(groups.first.id); // 첫 번째 그룹의 이벤트 로드
      }

      if (groups.isEmpty && overallStatistics == null) {
        hasError = true;
      }
    } catch (e) {
      print("Error loading data: $e");
      hasError = true;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadEventsForGroup(int groupId) async {
    setState(() {
      _selectedEvents = groupRankings[groupId]?.events ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError || (groups.isEmpty)
          ? const Center(child: Text("정보를 불러올 수 없습니다."))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYearSelector(),
              const SizedBox(height: 16),
              _buildStatisticsCard(), // 전체 통계 카드
              const SizedBox(height: 16),
              _buildClubRankingSection(), // 그룹 랭킹 섹션
              const SizedBox(height: 16),
              _buildEventListSection(), // 클릭한 모임의 이벤트 섹션
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildYearButton('전체'),
        _buildYearButton('2023년'),
        _buildYearButton('2024년'),
        _buildYearButton('기간 선택'),
      ],
    );
  }

  Widget _buildYearButton(String title) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedYear = title;
          _loadInitialData();
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(title),
    );
  }

  // 전체 통계 카드 표시
  Widget _buildStatisticsCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('평균', overallStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
        _buildStatCard('베스트 스코어', overallStatistics?.bestScore.toString() ?? 'N/A', Colors.yellow),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubRankingSection() {
    if (groups.isEmpty) {
      return const Center(child: Text('그룹 데이터를 불러오는 중...'));
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '모임별 랭킹',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: groups.map((group) {
                ClubStatistics? ranking = groupRankings[group.id];
                return GestureDetector(
                  onTap: () {
                    _loadEventsForGroup(group.id); // 클릭된 그룹의 이벤트 리스트 로드
                  },
                  child: _buildClubCircle(
                    group.name,
                    ranking != null && ranking.ranking.totalRank != null
                        ? ranking.ranking.totalRank.toString()
                        : "랭킹 불러오는 중...",
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCircle(String groupName, String rank) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          child: Text(
            groupName.substring(0, 1), // 그룹 이름의 첫 글자만 보여줌
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(rank, style: const TextStyle(fontSize: 14)), // 그룹별 랭킹 표시
      ],
    );
  }

  // 모임 클릭 시 해당 모임의 이벤트 리스트를 표시하는 섹션
  Widget _buildEventListSection() {
    if (_selectedEvents.isEmpty) {
      return const Center(child: Text('이벤트 데이터를 불러오는 중...'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _selectedEvents.map((event) {
        // 비율 계산: (총 참가자 수 - 랭킹) / 총 참가자 수
        double fillPercentage = (event.totalParticipants - int.parse(event.rank)) / event.totalParticipants;
        Color barColor = Color.lerp(Colors.green, Colors.lightGreen[200], fillPercentage)!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.eventName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fillPercentage,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('참가자 수: ${event.totalParticipants}명, 순위: ${event.rank}위'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
