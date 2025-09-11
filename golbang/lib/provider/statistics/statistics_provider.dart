import 'package:flutter/material.dart';
import 'package:golbang/services/statistics_service.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/models/get_statistics_yearly.dart';
import 'package:golbang/models/get_statistics_period.dart';

class StatisticsProvider with ChangeNotifier {
  final StatisticsService statisticsService;

  OverallStatistics? overallStatistics;
  YearStatistics? yearStatistics;
  PeriodStatistics? periodStatistics;
  bool isLoading = false;

  StatisticsProvider(this.statisticsService);

  // 전체 통계 조회
  Future<void> fetchOverallStatistics() async {
    isLoading = true;
    notifyListeners();

    overallStatistics = await statisticsService.fetchOverallStatistics();

    isLoading = false;
    notifyListeners();
  }

  // 연도별 통계 조회
  Future<void> fetchYearStatistics(String year) async {
    isLoading = true;
    notifyListeners();

    yearStatistics = await statisticsService.fetchYearStatistics(year);

    isLoading = false;
    notifyListeners();
  }

  // 기간별 통계 조회
  Future<void> fetchPeriodStatistics(String startDate, String endDate) async {
    isLoading = true;
    notifyListeners();

    periodStatistics = await statisticsService.fetchPeriodStatistics(startDate, endDate);

    isLoading = false;
    notifyListeners();
  }

  // 모든 통계를 초기화
  void resetStatistics() {
    overallStatistics = null;
    yearStatistics = null;
    periodStatistics = null;
    notifyListeners();
  }
}
