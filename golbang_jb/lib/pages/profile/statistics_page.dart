import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/models/get_statistics_yearly.dart';
import 'package:golbang/models/get_statistics_period.dart';
import 'package:golbang/models/get_statistics_ranks.dart';
import 'package:golbang/services/group_service.dart';
import '../../services/statistics_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../../models/club.dart'; // 그룹 모델 추가

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  late StatisticsService statisticsService;
  late GroupService groupService; // 그룹 서비스 추가
  String selectedYear = '전체'; // 초기 연도 설정
  List<String> years = [];

  List<Club> clubs = []; // 그룹 리스트
  Map<int, ClubStatistics> groupRankings = {}; // 그룹별 랭킹 데이터
  List<EventStatistics> _selectedEvents = []; // 클릭한 모임의 이벤트 리스트
  OverallStatistics? overallStatistics; // 전체 통계 선언
  YearStatistics? yearStatistics; // 연도별 통계 선언
  bool isLoading = true;
  bool hasError = false;

  DateTime? startDate;
  DateTime? endDate;
  PeriodStatistics? periodStatistics; // 기간별 통계 데이터
  final Map<int, List<EventStatistics>> _cachedEvents = {}; // 그룹별 이벤트 캐시

  @override
  void initState() {
    super.initState();
    // years 리스트 생성 (현재 연도 ~ 2000)
    for (int i = DateTime.now().year; i>= 2000; i--) {
      years.add('$i');
    }
    years.insert(0, '전체'); // 첫 번째 옵션으로 "전체" 추가
  }

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
    final startTime = DateTime.now();

    try {
      clubs = await groupService.getUserGroups();
      if (clubs.isNotEmpty) {
        // 첫 번째 그룹의 랭킹 및 이벤트 리스트 가져오기
        ClubStatistics? ranking = await groupService.fetchGroupRanking(clubs.first.id);
        if (ranking != null) {
          groupRankings[clubs.first.id] = ranking;
          _cachedEvents[clubs.first.id] = ranking.events ?? [];
          _selectedEvents = _cachedEvents[clubs.first.id]!;
        }
      }
      await _loadStatisticsData();
      if (clubs.isNotEmpty && groupRankings.isNotEmpty) {
        _loadEventsForGroup(clubs.first.id);
      }
      if (clubs.isEmpty && overallStatistics == null && yearStatistics == null) {
        hasError = true;
      }
    } catch (e) {
      log("Error loading data: $e");
      hasError = true;
    } finally {
      final endTime = DateTime.now(); // 종료 시간 기록
      log("Data fetching took: ${endTime.difference(startTime).inMilliseconds} ms");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadStatisticsData() async {
    try {
      final startTime = DateTime.now();
      if (selectedYear == '전체') {
        // 전체 통계 가져오기
        overallStatistics = await statisticsService.fetchOverallStatistics();
        yearStatistics = null;
      } else if (selectedYear != "전체") {
        // 연도별 통계 가져오기 (startDate, endDate는 사용하지 않음)
        yearStatistics = await statisticsService.fetchYearStatistics(selectedYear);
        overallStatistics = null;
        periodStatistics = null; // 기간 통계 데이터를 초기화
      } else if (startDate != null && endDate != null) {
        // 기간 통계 가져오기 (선택된 날짜에 대한 통계)
        await _loadPeriodStatistics();
      }
      final endTime = DateTime.now(); // 종료 시간 기록
      log("Statistic Data fetching took: ${endTime.difference(startTime).inMilliseconds} ms");
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  Future<void> _loadEventsForGroup(int groupId) async {
    log("Loading events for group ID: $groupId");
    if (_cachedEvents.containsKey(groupId)) {
      // 이미 캐싱된 데이터가 있으면 캐싱된 데이터를 사용
      setState(() {
        _selectedEvents = _cachedEvents[groupId]!;
      });
      log("Using cached events for group ID: $groupId");
      return;
    }

    try {
      final startTime = DateTime.now();
      // 그룹 데이터 가져오기
      ClubStatistics? ranking = await groupService.fetchGroupRanking(groupId);
      if (ranking != null) {
        final List<EventStatistics> events = ranking.events ?? [];
        setState(() {
          _cachedEvents[groupId] = events; // 캐싱
          _selectedEvents = events; // UI 업데이트
        });
        log("Loaded events for group ID: $groupId");
      } else {
        log("No ranking data available for group ID: $groupId");
        setState(() {
          _selectedEvents = [];
        });
      }
      final endTime = DateTime.now(); // 종료 시간 기록
      log("Each Data fetching took: ${endTime.difference(startTime).inMilliseconds} ms");
    } catch (e) {
      log("Failed to load events for group ID $groupId: $e");
      setState(() {
        _selectedEvents = [];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.now(); // 시작 시간 기록

    final widgetTree = Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('통계'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop()
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError || (clubs.isEmpty)
          ? const Center(child: Text("정보를 불러올 수 없습니다."))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYearSelector(),
              const SizedBox(height: 8),
              _buildStatisticsCard(), // 전체 통계 또는 연도별 통계 카드
              const SizedBox(height: 8),
              _buildClubRankingSection(), // 그룹 랭킹 섹션
              const SizedBox(height: 8),
              _buildEventListSection(), // 클릭한 모임의 이벤트 섹션
            ],
          ),
        ),
      ),
    );

    final endTime = DateTime.now(); // 종료 시간 기록
    log("Widget build took: ${endTime.difference(startTime).inMilliseconds} ms");

    return widgetTree;
  }

  Widget _buildYearSelector() {
    const double elementWidth = 120.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: elementWidth,
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String>(
            value: years.contains(selectedYear) ? selectedYear : null,
            hint: const Text('연도 선택'),
            isExpanded: true,
            items: years.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  isLoading = true;
                  selectedYear = newValue;
                  startDate = null; // 데이터 범위 리셋
                  endDate = null;
                  periodStatistics = null; // period statistics 리셋
                });
                await _loadStatisticsData();
                setState(() {
                  isLoading = false;
                });
              }
            },
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
            dropdownColor: Colors.white,
            underline: Container(
              height: 1,
              color: Colors.green,
            ),
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: elementWidth,
          child: ElevatedButton(
            onPressed: () => _selectDateRange(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '기간 선택',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
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

      log("Selected date range: $startDate to $endDate");
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

        log("Loading period statistics from $formattedStartDate to $formattedEndDate");
        periodStatistics = await statisticsService.fetchPeriodStatistics(formattedStartDate, formattedEndDate);

        // 데이터 수신 후 상태 갱신
        setState(() {
          periodStatistics = periodStatistics; // 상태를 다시 설정해 화면을 갱신합니다.
        });
      } catch (e) {
        log("Failed to load period statistics: $e");
        setState(() {
          hasError = true;
        });
      }
    }
  }

  // 전체, 연도별, 기간별 통계 표시 카드
  Widget _buildStatisticsCard() {
    if (selectedYear == '전체' && overallStatistics != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('평균', overallStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
          _buildStatCard('베스트 스코어', overallStatistics?.bestScore.toString() ?? 'N/A', Colors.orange),
        ],
      );
    } else if (selectedYear != '' && yearStatistics != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('평균', yearStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
          _buildStatCard('베스트 스코어', yearStatistics?.bestScore.toString() ?? 'N/A', Colors.orange),
        ],
      );
    } else if (periodStatistics != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('평균', periodStatistics?.averageScore.toString() ?? 'N/A', Colors.green),
          _buildStatCard('베스트 스코어', periodStatistics?.bestScore.toString() ?? 'N/A', Colors.orange),
        ],
      );
    } else {
      return const Center(child: Text('해당 기간에 이벤트가 존재하지 않아 데이터를 불러올 수 없습니다.'));
    }
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
    if (clubs.isEmpty) {
      return const Center(child: Text('모임의 이벤트 데이터가 없습니다.'));
    }

    return Card(
      color: Colors.white,
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
              scrollDirection: Axis.horizontal,
              child: Row(
                children: clubs.map((group) {
                  ClubStatistics? ranking = groupRankings[group.id];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () async {
                        await _loadEventsForGroup(group.id); // 그룹 ID로 이벤트 데이터 로드
                        setState(() {}); // 상태 변경을 트리거하여 UI 업데이트
                      },
                      child: _buildClubCircle(
                        group.name,
                        group.image,
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



  Widget _buildClubCircle(String groupName, String? imagePath) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: imagePath != null && imagePath.contains('http')
              ? NetworkImage(imagePath) // 네트워크 이미지
              : imagePath != null
              ? AssetImage(imagePath) as ImageProvider // 로컬 파일
              : null, // 이미지가 없으면 null 처리
          backgroundColor: Colors.transparent, // 배경을 투명색으로 설정
          child: imagePath == null
              ? Text(
            groupName.substring(0, 1), // 그룹 이름의 첫 글자만 보여줌
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
              : null, // 이미지가 있으면 텍스트를 숨김
        ),
        const SizedBox(height: 8),
        Text(groupName, style: const TextStyle(fontSize: 14)), // 그룹 이름 표시
      ],
    );
  }

  // 모임 클릭 시 해당 모임의 이벤트 리스트를 표시하는 섹션
  Widget _buildEventListSection() {
    if (_selectedEvents.isEmpty) {
      return const Center(child: Text('해당 모임에 아직 이벤트가 없습니다.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _selectedEvents.map((event) {
        double fillPercentage = 0;

        if (event.totalParticipants != 0 && event.points >= 2) {
          fillPercentage = (event.points - 2) / event.totalParticipants;
          if (fillPercentage > 1) {
            fillPercentage = 1;
          }
        }

        if (fillPercentage.isNaN || fillPercentage.isInfinite) {
          fillPercentage = 0;
        }

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
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
