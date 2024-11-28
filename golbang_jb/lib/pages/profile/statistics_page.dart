import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/models/get_statistics_yearly.dart';
import 'package:golbang/models/get_statistics_period.dart';
import 'package:golbang/models/get_statistics_ranks.dart';
import 'package:golbang/services/group_service.dart';
import '../../services/statistics_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../../models/group.dart'; // 그룹 모델 추가

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  late StatisticsService statisticsService;
  late GroupService groupService; // 그룹 서비스 추가
  String selectedYear = '전체'; // 초기 연도 설정

  List<Group> groups = []; // 그룹 리스트
  Map<int, ClubStatistics> groupRankings = {}; // 그룹별 랭킹 데이터
  List<EventStatistics> _selectedEvents = []; // 클릭한 모임의 이벤트 리스트
  OverallStatistics? overallStatistics; // 전체 통계 선언
  YearStatistics? yearStatistics; // 연도별 통계 선언
  bool isLoading = true;
  bool hasError = false;

  DateTime? startDate;
  DateTime? endDate;
  PeriodStatistics? periodStatistics; // 기간별 통계 데이터

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // SecureStorage를 가져와서 서비스 초기화
    final secureStorage = ref.watch(secureStorageProvider);
    statisticsService = StatisticsService(secureStorage);
    groupService = GroupService(secureStorage);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      groups = await groupService.getUserGroups();
      for (Group group in groups) {
        ClubStatistics? ranking = await groupService.fetchGroupRanking(group.id);
        if (ranking != null) {
          groupRankings[group.id] = ranking;
        }
      }
      await _loadStatisticsData();
      if (groups.isNotEmpty && groupRankings.isNotEmpty) {
        _loadEventsForGroup(groups.first.id);
      }
      if (groups.isEmpty && overallStatistics == null && yearStatistics == null) {
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

  Future<void> _loadStatisticsData() async {
    try {
      if (selectedYear == '전체') {
        // 전체 통계 가져오기
        overallStatistics = await statisticsService.fetchOverallStatistics();
        yearStatistics = null;
      } else if (selectedYear == '2023' || selectedYear == '2024') {
        // 연도별 통계 가져오기 (startDate, endDate는 사용하지 않음)
        yearStatistics = await statisticsService.fetchYearStatistics(selectedYear);
        overallStatistics = null;
        periodStatistics = null; // 기간 통계 데이터를 초기화
      } else if (startDate != null && endDate != null) {
        // 기간 통계 가져오기 (선택된 날짜에 대한 통계)
        await _loadPeriodStatistics();
      }
    } catch (e) {
      setState(() {
        hasError = true;
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
              _buildStatisticsCard(), // 전체 통계 또는 연도별 통계 카드
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
        _buildYearButton('2024년'),
        _buildYearButton('2023년'),
        ElevatedButton(
          onPressed: () => _selectDateRange(context), // 기간 선택 버튼
          child: const Text('기간 선택'),
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate!, end: endDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 1))),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        selectedYear = ''; // 연도 선택 초기화
      });

      print("Selected date range: $startDate to $endDate");
      await _loadPeriodStatistics(); // 기간별 통계 로드
    }
  }

  Future<void> _loadPeriodStatistics() async {
    if (startDate != null && endDate != null) {
      final String formattedStartDate = "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
      final String formattedEndDate = "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";

      try {
        setState(() {
          overallStatistics = null; // 전체 통계 초기화
          yearStatistics = null; // 연도별 통계 초기화
        });

        print("Loading period statistics from $formattedStartDate to $formattedEndDate");
        periodStatistics = await statisticsService.fetchPeriodStatistics(formattedStartDate, formattedEndDate);

        // 데이터 수신 후 상태 갱신
        setState(() {
          periodStatistics = periodStatistics; // 상태를 다시 설정해 화면을 갱신합니다.
        });
      } catch (e) {
        print("Failed to load period statistics: $e");
        setState(() {
          hasError = true;
        });
      }
    }
  }


  // 기간 선택 버튼 아래에 선택된 기간을 표시
  Widget _buildDateRangeDisplay() {
    if (startDate != null && endDate != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          "선택된 기간: ${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')} ~ ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
    return const SizedBox.shrink(); // 선택된 날짜가 없으면 빈 공간을 반환
  }

  Widget _buildYearButton(String title) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          isLoading = true;
          selectedYear = title.replaceAll('년', '');
          // 연도별 통계를 선택할 때 기간 선택 데이터를 초기화
          startDate = null;
          endDate = null;
          periodStatistics = null; // 기간 통계 데이터를 초기화
        });

        // 비동기 작업 완료 후 데이터 로드
        await _loadStatisticsData();

        // 로딩이 끝난 후 화면 갱신
        setState(() {
          isLoading = false;
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


  // 전체, 연도별, 기간별 통계 표시 카드
  Widget _buildStatisticsCard() {
    if (selectedYear == '전체' && overallStatistics != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('평균', overallStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
          _buildStatCard('베스트 스코어', overallStatistics?.bestScore.toString() ?? 'N/A', Colors.yellow),
        ],
      );
    } else if (selectedYear != '' && yearStatistics != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('평균', yearStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
          _buildStatCard('베스트 스코어', yearStatistics?.bestScore.toString() ?? 'N/A', Colors.yellow),
        ],
      );
    } else if (periodStatistics != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('평균', periodStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
          _buildStatCard('베스트 스코어', periodStatistics?.bestScore.toString() ?? 'N/A', Colors.yellow),
        ],
      );
    } else {
      return const Center(child: Text('해당 기간에 이벤트가 존재하지 않아 데이터를 불러올 수 없습니다.'));
    }
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
      return const Center(child: Text('모임의 이벤트 데이터가 없습니다.'));
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 스크롤 활성화
              child: Row(
                children: groups.map((group) {
                  ClubStatistics? ranking = groupRankings[group.id];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // child 간 가로 간격 추가
                    child: GestureDetector(
                      onTap: () {
                        _loadEventsForGroup(group.id); // 클릭된 그룹의 이벤트 리스트 로드
                      },
                      child: _buildClubCircle(
                        group.name,
                        group.image,
                        ranking != null && ranking.ranking.totalRank != null
                            ? ranking.ranking.totalRank.toString()
                            : "랭킹 불러오는 중...",
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCircle(String groupName, String? imagePath, String rank) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: imagePath != null
              ? AssetImage(imagePath) // 이미지가 있으면 로컬 이미지 사용
              : null, // 이미지가 없으면 배경 이미지를 표시하지 않음
          child: imagePath == null // 이미지가 없을 경우만 텍스트 표시
              ? Text(
            groupName.substring(0, 1), // 그룹 이름의 첫 글자만 보여줌
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
              : null, // 이미지가 있으면 텍스트를 숨김
        ),
        const SizedBox(height: 8),
        Text(rank + groupName, style: const TextStyle(fontSize: 14)), // 그룹별 랭킹 표시
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
        double fillPercentage = 0;

        // 참가자 수가 0이거나 event.points가 2보다 작으면 예외 처리
        if (event.totalParticipants != 0 && event.points >= 2) {
          fillPercentage = (event.points - 2) / event.totalParticipants;
          if (fillPercentage > 1) {
            fillPercentage = 1;
          }
        }
        // 예외 처리: fillPercentage가 유효하지 않은 경우 0으로 설정
        if (fillPercentage.isNaN || fillPercentage.isInfinite) {
          fillPercentage = 0;
        }
        print(event.points);
        print(event.totalParticipants);
        print("fillPercentage:, $fillPercentage");

        // Color.lerp에 fillPercentage를 사용
        Color barColor = Color.lerp(Colors.yellow, Colors.green, fillPercentage)!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.eventName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // 전체 배경
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],  // 전체 배경 색
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // 채워지는 부분
                  FractionallySizedBox(
                    widthFactor: fillPercentage,  // fillPercentage만큼 너비 조절 (0.0 ~ 1.0)
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: barColor,  // fillPercentage에 따른 색상
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
